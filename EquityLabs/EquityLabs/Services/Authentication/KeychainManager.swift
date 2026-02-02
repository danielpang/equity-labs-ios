import Foundation
import Security

// MARK: - KeychainManager
class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    // MARK: - Save
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }

        AppLogger.authentication.debug("Saved value to keychain for key: \(key)")
    }

    // MARK: - Load
    func load(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.loadFailed(status)
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return value
    }

    // MARK: - Delete
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }

        AppLogger.authentication.debug("Deleted value from keychain for key: \(key)")
    }

    // MARK: - Delete All
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }

        AppLogger.authentication.info("Deleted all values from keychain")
    }
}

// MARK: - KeychainError
enum KeychainError: LocalizedError {
    case invalidData
    case itemNotFound
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .itemNotFound:
            return "Item not found in keychain"
        case .saveFailed(let status):
            return "Failed to save to keychain (Status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from keychain (Status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain (Status: \(status))"
        }
    }
}
