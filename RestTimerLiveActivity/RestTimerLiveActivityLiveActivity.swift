import ActivityKit
import WidgetKit
import SwiftUI

struct RestTimerLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock Screen / Banner
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                        .frame(width: 44, height: 44)
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if context.state.timerEnd > .now {
                        Text(timerInterval: .now...context.state.timerEnd, countsDown: true)
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    } else {
                        Text("0:00")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.green)
                    }
                }

                Spacer()
            }
            .padding()
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("Rest Timer")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if context.state.timerEnd > .now {
                            Text(timerInterval: .now...context.state.timerEnd, countsDown: true)
                                .font(.title3.bold().monospacedDigit())
                        } else {
                            Text("0:00")
                                .font(.title3.bold())
                                .foregroundStyle(.green)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {}
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                if context.state.timerEnd > .now {
                    Text(timerInterval: .now...context.state.timerEnd, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 44)
                        .foregroundStyle(.blue)
                } else {
                    Text("0:00")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            }
        }
    }
}
