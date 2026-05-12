// ABOUTME: Entry point for the Frank Energie widget extension bundle.
// ABOUTME: Registers all available widgets with the system.

import WidgetKit
import SwiftUI

@main
struct FrankEnergieWidgetBundle: WidgetBundle {
    var body: some Widget {
        FrankEnergieElectricityWidget()
    }
}
