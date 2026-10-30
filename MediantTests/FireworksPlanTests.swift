import CoreGraphics
import Foundation
import Testing
@testable import Mediant

struct FireworksPlanTests {
    let phone = CGSize(width: 393, height: 852)

    @Test func rocketCountPerSize() {
        let expected: [TipSize: Int] = [.small: 1, .medium: 2, .large: 3, .huge: 6]
        for size in TipSize.allCases {
            let plan = FireworksPlan(size: size, canvas: phone, seed: 7)
            #expect(plan.rockets.count == expected[size])
            let finales = plan.rockets.indices.filter { plan.rockets[$0].isFinale }
            #expect(finales == (size == .huge ? [5] : []))
        }
    }

    @Test func launchesAreSpaced() {
        let launches = FireworksPlan(size: .large, canvas: phone, seed: 3).rockets.map(\.launch)
        let expected: [TimeInterval] = [0, 0.38, 0.76]
        #expect(launches.count == expected.count)
        for (launch, wanted) in zip(launches, expected) {
            #expect(abs(launch - wanted) < 0.001)
        }
    }

    @Test func finaleLaunchesLastAtTheCenter() {
        let plan = FireworksPlan(size: .huge, canvas: phone, seed: 5)
        let finale = plan.rockets[5]
        #expect(abs(finale.launch - (4 * 0.38 + 0.35)) < 0.001)
        #expect(abs(finale.burst.x - phone.width / 2) < 0.001)
        #expect(abs(finale.burst.y - 0.36 * phone.height) < 0.001)
        #expect(plan.rockets.dropLast().allSatisfy { !$0.isFinale && $0.launch < finale.launch })
    }

    @Test func burstsStayOnScreen() {
        for size in TipSize.allCases {
            for canvas in [CGSize(width: 393, height: 852), CGSize(width: 375, height: 667)] {
                for seed in UInt64(1)...50 {
                    for rocket in FireworksPlan(size: size, canvas: canvas, seed: seed).rockets {
                        // The rim dots fly out to 1.25 × the radius.
                        let reach = 1.25 * rocket.radius
                        if 2 * reach <= canvas.width {
                            #expect(rocket.burst.x - reach >= -0.001)
                            #expect(rocket.burst.x + reach <= canvas.width + 0.001)
                        } else {
                            // Wider than the screen (the finale, a single rocket above 0.4 W).
                            #expect(abs(rocket.burst.x - canvas.width / 2) < 0.001)
                        }
                        // The streaks always fit.
                        #expect(rocket.burst.x - rocket.radius >= 0)
                        #expect(rocket.burst.x + rocket.radius <= canvas.width)
                        #expect(rocket.burst.y - reach >= 0)
                        #expect(rocket.burst.y <= 0.45 * canvas.height + 0.001)
                    }
                }
            }
        }
    }

    @Test func rocketsFlyFromBelowTheBottom() {
        for rocket in FireworksPlan(size: .huge, canvas: phone, seed: 9).rockets {
            #expect(rocket.start.y == phone.height + 10)
            #expect(rocket.flight >= 0.75 && rocket.flight <= 0.95)
            #expect(abs(rocket.bend) <= 0.17 * phone.width + 0.001)
        }
    }

    @Test func radiiScaleWithWidth() {
        for rocket in FireworksPlan(size: .large, canvas: phone, seed: 1).rockets {
            #expect(rocket.radius >= 0.24 * 393 - 0.001 && rocket.radius <= 0.32 * 393 + 0.001)
        }
        for width: CGFloat in [393, 375] {
            let plan = FireworksPlan(size: .huge, canvas: CGSize(width: width, height: 852), seed: 1)
            #expect(abs(plan.rockets[5].radius - 0.46 * width) < 0.001)
        }
    }

    @Test func pairIsTheRocketIndex() {
        let pairs = FireworksPlan(size: .large, canvas: phone, seed: 2).rockets.map(\.pair)
        #expect(pairs == [0, 1, 2])
    }

    @Test func sameSeedSamePlan() {
        #expect(FireworksPlan(size: .huge, canvas: phone, seed: 42) == FireworksPlan(size: .huge, canvas: phone, seed: 42))
    }

    @Test func otherSeedOtherPlan() {
        #expect(FireworksPlan(size: .huge, canvas: phone, seed: 1) != FireworksPlan(size: .huge, canvas: phone, seed: 2))
    }

    @Test func hugeEndsInAboutFourSeconds() {
        let duration = FireworksPlan(size: .huge, canvas: phone, seed: 11).duration
        #expect(duration > 3.5 && duration < 4.5)
    }
}
