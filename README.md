<div align="center">

[![Platforms][platforms badge]][platforms]
[![Matrix][matrix badge]][matrix]

</div>

# Outline
A SwiftUI wrapper around NSOutlineView that supports lazy child loading.

`NSOutlineView` (and `NSTableView`) can do an an enormous amount. This SwiftUI view can do just a little, but offers lazy, async child loading which `OutlineGroup` cannot (currently) do. Hopefully one day! But in the meantime, maybe this will come in handy.

## Usage

```swift
@MainActor
@Observable
final class OutlineModel {
    private(set) var outlineData: OutlineData<MyItem, String>

    var expansion = Set<String>()
    var selection = Set<String>()

    init() {
        self.outlineData = OutlineData(
            root: ..., // fill this in with your node type
            subValues: {
                // an async context to load children
                return $0.children()
            },
            id: \.id,
            hasSubvalues: \.hasChildren
        )
    }

    static func configureView(_ view: NSOutlineView) {
        // customize the view here
    }
}

public struct Navigator: View {
    @State private var model =  OutlineModel()
    
    var body: some View {
        OutlineView(
            data: model.outlineData,     // core outline tree data
            expansion: $model.expansion, // control expansion state
            selection: $model.selection, // .. and selection
            configuration: OutlineModel.configureView // optionally customize the underlying NSOutlineView
        ) { value in
            Text(value.name)
        }
    }
}
```

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. Both a [Matrix space][matrix] and [Discord][discord] are available for live help, but I have a strong bias towards answering in the form of documentation. You can also find me on [mastodon](https://mastodon.social/@mattiem).

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[platforms]: https://swiftpackageindex.com/ChimeHQ/Outline
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FOutline%2Fbadge%3Ftype%3Dplatforms
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
