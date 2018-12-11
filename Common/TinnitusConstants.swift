// Keys used by the dictionaries when communicating between the watch and the phone.

enum MessageKey: String {
    case command
    case stateUpdate
    case acknowledge = "ack"
}

// Used by the dicationaries when communicating between the watch and the phone.
enum MessageCommand: String {
    case sendLocationStatus
    case startUpdatingLocation
    case stopUpdatingLocation
}

// Set to false if sent to test users.
let IsDebug = false
