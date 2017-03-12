/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import MarathonCore

do {
    let outcome = try Marathon.run()

    if !outcome.isEmpty {
        print(outcome)
    }
} catch {
    print("\(error)")
}
