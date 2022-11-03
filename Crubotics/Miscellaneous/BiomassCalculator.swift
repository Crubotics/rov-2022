//
//  BiomassCalculator.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/8/22.
//

import SwiftUI

struct BiomassCalculator: View {
    @State private var averageLength: Int = 0

    var body: some View {
        VStack {
            Form {
                TextField("Average length", value: $averageLength, format: .number)

                Spacer()
            }.textFieldStyle(.roundedBorder)
        }
    }
}

struct BiomassCalculator_Previews: PreviewProvider {
    static var previews: some View {
        BiomassCalculator()
    }
}
