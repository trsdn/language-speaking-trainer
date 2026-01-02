import Foundation
import Security

/// Minimal Keychain wrapper for storing small secrets.
///
/// Design goal: callers should treat values as *write-only* at the UI level.
/// The app still needs read access internally to make authenticated requests.
enum KeychainStore {
    enum SecretKey: String {
        // Reserved for future BYOK support:
        case openAIAPIKey = "openai_api_key"
    }

    private static var service: String {
        Bundle.main.bundleIdentifier ?? "LanguageSpeakingTrainer"
    }

    static func readString(for key: SecretKey) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]

        // Allow reads from the foreground; do not require user presence.
        // (This is a dev convenience; for higher security, consider access control flags.)
        query[kSecUseDataProtectionKeychain as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        guard let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func writeString(_ value: String, for key: SecretKey) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecUseDataProtectionKeychain as String: true,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            // Keep the secret only on this device.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        if updateStatus != errSecItemNotFound {
            throw KeychainError(status: updateStatus)
        }

        var addQuery = query
        for (k, v) in attributes {
            addQuery[k] = v
        }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError(status: addStatus)
        }
    }

    static func delete(_ key: SecretKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecUseDataProtectionKeychain as String: true,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }
        throw KeychainError(status: status)
    }
}

struct KeychainError: Error {
    let status: OSStatus
}
