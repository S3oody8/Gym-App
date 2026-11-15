import Foundation
import SwiftData

/// All SwiftData model types, in one place for the app and tests.
enum ModelSchema {
    static let models: [any PersistentModel.Type] = [
        Exercise.self,
        WorkoutSession.self,
        SessionExercise.self,
        WorkoutSet.self,
        WorkoutTemplate.self,
        TemplateExercise.self,
    ]

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
