## Deployment

### Homebrew

In order to make it possible for others to use Marathon globally, Marathon supports being installeed via `brew install marathon-swift`.

To update the homebrew version of Marathon, you need to:

* Create a tag for the release, `git tag 3.0.0`
* Update the formula on homebrew-core, by running: `brew bump-formula-pr  --url=https://github.com/JohnSundell/Marathon/archive/3.0.0.tar.gz --audit`.
