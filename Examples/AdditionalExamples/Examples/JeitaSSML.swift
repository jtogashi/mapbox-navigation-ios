//
//  JeitaSSML.swift
//  Examples
//
//  Created by Jumpei Togashi on 2026/10/07.
//

@available(iOS 16.0, *)
public struct JeitaSSML {
    let ssml: String

    private static let jeitaRegex = /<phoneme alphabet="jeita" ph="([^<>]+)">([^<>]+)<\/phoneme>/

    var stripped: String {
        let matches = ssml.matches(of: Self.jeitaRegex)
        var strippedAll = String(ssml)
        for match in matches {
            var phoneme = String(match.1)
            phoneme.replace(/[ :]/, with: ",") // preserve breaks
            phoneme.replace(/[\x21-\x7E--,]/, with: "") // strip ASCIIs except for commas

            strippedAll.replace(match.0, with: phoneme, maxReplacements: 1)
        }
        return strippedAll
    }

    var polly: String {
        guard ssml.starts(with: "<speak><amazon:effect") else {
            return ssml
        }

        let matches = ssml.matches(of: Self.jeitaRegex)
        var polly = String(ssml)
        for match in matches {
            var phoneme = String(match.1)
            // convert all accent symbols into '
            phoneme.replace("&apos;", with: "'")
            phoneme.replace("&quot;", with: "'")
            phoneme.replace("*", with: "'")

            // covert breaks
            phoneme.replace(/[ :]/, with: ",")

            // strip ASCIIs except for accents and breaks
            phoneme.replace(/[\x21-\x7E--',]/, with: "")

            // escape accents back
            phoneme.replace("'", with: "&apos;")

            let fullwidth = toFullwidthKana(from: phoneme)

            polly.replace(match.0, with: "<phoneme alphabet=\"x-amazon-pron-kana\" ph=\"\(fullwidth)\">\(match.2)</phoneme>", maxReplacements: 1)
        }

        return polly
    }

    private func toFullwidthKana(from: String) -> String {
        var scalars: [Unicode.Scalar] = []

        for s in from.unicodeScalars {
            switch s.value {
            case 0xFF61...0xFF9D: // halfwidth kana -> fullwidth
                scalars.append(contentsOf: String(s)
                    .precomposedStringWithCompatibilityMapping.unicodeScalars)
            case 0xFF9E: // halfwidth voiced sound mark -> combining voiced sound mark
                scalars.append("\u{3099}")
            case 0xFF9F: // halfwidth semi-voiced sound mark -> combining semi-voiced sound mark
                scalars.append("\u{309A}")
            default:
                scalars.append(s)
            }
        }

        return String(String.UnicodeScalarView(scalars))
                    .precomposedStringWithCanonicalMapping
    }
}
