package main

import (
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	coreV1 "k8s.io/api/core/v1"
	metaV1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes/fake"
	k8sTesting "k8s.io/client-go/testing"
)

func TestShouldNotify(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		// counts は同じイベントが順に届いたときの count
		counts   []int32
		expected []bool
	}{
		{
			name:     "初見のイベントは通知する",
			counts:   []int32{1},
			expected: []bool{true},
		},
		{
			name:     "閾値に満たない再発は通知しない",
			counts:   []int32{1, 2, 3, 4, 5},
			expected: []bool{true, false, false, false, false},
		},
		{
			name:     "count が閾値ぶん増えたら再通知する",
			counts:   []int32{1, 5, 6, 11},
			expected: []bool{true, false, true, true},
		},
		{
			name:     "count が飛んでも 1 回だけ通知する",
			counts:   []int32{1, 12},
			expected: []bool{true, true},
		},
		{
			name:     "プロセス起動前から継続しているイベントも初見として通知する",
			counts:   []int32{47, 48},
			expected: []bool{true, false},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			handler := newEventHandler(&Config{}, nil, fake.NewClientset().CoreV1(), time.Time{})

			var actual []bool
			for _, count := range tt.counts {
				event := &coreV1.Event{
					ObjectMeta: metaV1.ObjectMeta{UID: types.UID("event")},
					Count:      count,
				}
				actual = append(actual, handler.shouldNotify(event))
			}

			assert.Equal(t, tt.expected, actual)
		})
	}
}

func TestShouldNotifyTracksEventsIndependently(t *testing.T) {
	t.Parallel()

	handler := newEventHandler(&Config{}, nil, fake.NewClientset().CoreV1(), time.Time{})

	first := &coreV1.Event{ObjectMeta: metaV1.ObjectMeta{UID: types.UID("first")}, Count: 1}
	second := &coreV1.Event{ObjectMeta: metaV1.ObjectMeta{UID: types.UID("second")}, Count: 1}

	assert.True(t, handler.shouldNotify(first))
	assert.True(t, handler.shouldNotify(second))

	first.Count = 2
	assert.False(t, handler.shouldNotify(first))
}

func TestHandleEventEvictsDeletedEvent(t *testing.T) {
	t.Parallel()

	handler := newEventHandler(&Config{}, nil, fake.NewClientset().CoreV1(), time.Time{})
	event := &coreV1.Event{ObjectMeta: metaV1.ObjectMeta{UID: types.UID("event")}, Count: 3}

	assert.True(t, handler.shouldNotify(event))
	assert.False(t, handler.shouldNotify(event))

	handler.handleEvent(t.Context(), watch.Event{Type: watch.Deleted, Object: event})

	// TTL で消えたイベントの状態は捨てられるので、再び初見として扱われる
	assert.True(t, handler.shouldNotify(event))
}

func TestIsTerminatingPodEvent(t *testing.T) {
	t.Parallel()

	deletionTimestamp := metaV1.NewTime(time.Now())

	tests := []struct {
		name     string
		event    *coreV1.Event
		pod      *coreV1.Pod
		getError error
		expected bool
	}{
		{
			name:     "削除中の Pod の Unhealthy は捨てる",
			event:    unhealthyPodEvent("default", "app-1"),
			pod:      &coreV1.Pod{ObjectMeta: metaV1.ObjectMeta{Namespace: "default", Name: "app-1", DeletionTimestamp: &deletionTimestamp, Finalizers: []string{"example.com/finalizer"}}},
			expected: true,
		},
		{
			name:     "既に削除された Pod の Unhealthy は捨てる",
			event:    unhealthyPodEvent("default", "app-2"),
			expected: true,
		},
		{
			name:     "生きている Pod の Unhealthy は残す",
			event:    unhealthyPodEvent("default", "app-3"),
			pod:      &coreV1.Pod{ObjectMeta: metaV1.ObjectMeta{Namespace: "default", Name: "app-3"}},
			expected: false,
		},
		{
			name:     "Pod を取得できないときは残す",
			event:    unhealthyPodEvent("default", "app-4"),
			getError: errors.New("connection refused"),
			expected: false,
		},
		{
			name: "Pod 以外の Unhealthy は Pod を引かない",
			event: &coreV1.Event{
				Reason:         "Unhealthy",
				InvolvedObject: coreV1.ObjectReference{Kind: "Node", Namespace: "", Name: "lily"},
			},
			expected: false,
		},
		{
			name: "Unhealthy 以外は Pod を引かない",
			event: &coreV1.Event{
				Reason:         "BackOff",
				InvolvedObject: coreV1.ObjectReference{Kind: "Pod", Namespace: "default", Name: "app-5"},
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var objects []runtime.Object
			if tt.pod != nil {
				objects = append(objects, tt.pod)
			}

			clientSet := fake.NewClientset(objects...)
			if tt.getError != nil {
				clientSet.PrependReactor("get", "pods", func(k8sTesting.Action) (bool, runtime.Object, error) {
					return true, nil, tt.getError
				})
			}

			handler := newEventHandler(&Config{}, nil, clientSet.CoreV1(), time.Time{})

			assert.Equal(t, tt.expected, handler.isTerminatingPodEvent(t.Context(), tt.event))
		})
	}
}

func TestEventCount(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name     string
		event    *coreV1.Event
		expected int32
	}{
		{
			name:     "count をそのまま使う",
			event:    &coreV1.Event{Count: 7},
			expected: 7,
		},
		{
			name:     "events.k8s.io のイベントは series.count を使う",
			event:    &coreV1.Event{Series: &coreV1.EventSeries{Count: 3}},
			expected: 3,
		},
		{
			name:     "どちらも無いときは 1 とみなす",
			event:    &coreV1.Event{},
			expected: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			assert.Equal(t, tt.expected, eventCount(tt.event))
		})
	}
}

func TestEventTimestamp(t *testing.T) {
	t.Parallel()

	base := time.Date(2026, 9, 20, 9, 0, 0, 0, time.UTC)

	tests := []struct {
		name     string
		event    *coreV1.Event
		expected time.Time
	}{
		{
			name: "series があれば最終観測時刻を使う",
			event: &coreV1.Event{
				FirstTimestamp: metaV1.NewTime(base),
				LastTimestamp:  metaV1.NewTime(base.Add(time.Minute)),
				Series:         &coreV1.EventSeries{LastObservedTime: metaV1.NewMicroTime(base.Add(2 * time.Minute))},
			},
			expected: base.Add(2 * time.Minute),
		},
		{
			name: "lastTimestamp を優先する",
			event: &coreV1.Event{
				FirstTimestamp: metaV1.NewTime(base),
				LastTimestamp:  metaV1.NewTime(base.Add(time.Minute)),
			},
			expected: base.Add(time.Minute),
		},
		{
			name: "events.k8s.io のイベントは eventTime を使う",
			event: &coreV1.Event{
				EventTime: metaV1.NewMicroTime(base),
			},
			expected: base,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			assert.Equal(t, tt.expected, eventTimestamp(tt.event).UTC())
		})
	}
}

func TestFilterEvent(t *testing.T) {
	t.Parallel()

	syncedAt := time.Date(2026, 9, 20, 9, 0, 0, 0, time.UTC)
	after := metaV1.NewTime(syncedAt.Add(time.Minute))

	tests := []struct {
		name     string
		event    *coreV1.Event
		expected bool
	}{
		{
			name: "Warning は通す",
			event: &coreV1.Event{
				Type: coreV1.EventTypeWarning, Reason: "Unhealthy", LastTimestamp: after,
				Message: "Readiness probe failed: connection refused",
			},
			expected: true,
		},
		{
			name:     "Normal は捨てる",
			event:    &coreV1.Event{Type: coreV1.EventTypeNormal, Reason: "Started", LastTimestamp: after},
			expected: false,
		},
		{
			name: "同期時刻より前のイベントは捨てる",
			event: &coreV1.Event{
				Type: coreV1.EventTypeWarning, Reason: "Unhealthy",
				LastTimestamp: metaV1.NewTime(syncedAt.Add(-time.Minute)),
			},
			expected: false,
		},
		{
			name: "startup probe の失敗は捨てる",
			event: &coreV1.Event{
				Type: coreV1.EventTypeWarning, Reason: "Unhealthy", LastTimestamp: after,
				Message: "Startup probe failed: connection refused",
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			assert.Equal(t, tt.expected, filterEvent(tt.event, syncedAt))
		})
	}
}

func unhealthyPodEvent(namespace, name string) *coreV1.Event {
	return &coreV1.Event{
		ObjectMeta: metaV1.ObjectMeta{Namespace: namespace, Name: name + ".0"},
		Type:       coreV1.EventTypeWarning,
		Reason:     "Unhealthy",
		Message:    "Readiness probe failed: connection refused",
		InvolvedObject: coreV1.ObjectReference{
			Kind:      "Pod",
			Namespace: namespace,
			Name:      name,
		},
	}
}
