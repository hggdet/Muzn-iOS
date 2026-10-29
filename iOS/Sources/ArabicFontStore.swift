import CoreText
import Foundation

struct ImportedArabicFont {
    let postScriptName: String
    let displayName: String
    let fileURL: URL
}

enum ArabicFontStore {
    static let storedFontPathKey = "muzn.settings.importedArabicFontPath"

    static func registerBundledFont() {
        guard let fontURL = Bundle.main.url(forResource: "NotoSansArabic", withExtension: "ttf", subdirectory: "Fonts") else { return }
        _ = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }

    static func registerSavedFont() {
        guard let path = UserDefaults.standard.string(forKey: storedFontPathKey) else { return }
        _ = CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: path) as CFURL, .process, nil)
    }

    static func importFont(from sourceURL: URL) throws -> ImportedArabicFont {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        let fileManager = FileManager.default
        let supportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let fontDirectory = supportDirectory.appendingPathComponent("Muzn/Fonts", isDirectory: true)
        try fileManager.createDirectory(at: fontDirectory, withIntermediateDirectories: true)

        let destination = fontDirectory.appendingPathComponent("\(UUID().uuidString)-\(sourceURL.lastPathComponent)")
        try fileManager.copyItem(at: sourceURL, to: destination)

        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(destination as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first else {
            try? fileManager.removeItem(at: destination)
            throw ArabicFontImportError.invalidFont
        }

        let font = CTFontCreateWithFontDescriptor(descriptor, 0, nil)
        let postScriptName = CTFontCopyPostScriptName(font) as String
        guard CTFontManagerRegisterFontsForURL(destination as CFURL, .process, nil) else {
            try? fileManager.removeItem(at: destination)
            throw ArabicFontImportError.registrationFailed
        }

        UserDefaults.standard.set(destination.path, forKey: storedFontPathKey)
        return ImportedArabicFont(
            postScriptName: postScriptName,
            displayName: sourceURL.deletingPathExtension().lastPathComponent,
            fileURL: destination
        )
    }
}

enum ArabicFontImportError: LocalizedError {
    case invalidFont
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .invalidFont: "الملف المحدد ليس خطًا صالحًا بصيغة TTF أو OTF."
        case .registrationFailed: "تعذّر تسجيل هذا الخط؛ جرّب ملفًا آخر."
        }
    }
}
