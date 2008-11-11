### November 11, 2008

- Moved Bjax parameters from JSON encoding to Marshal.dump due to some translation issues.
- Removed automatic routing, require user to modify routes.rb

### November 6, 2008

- Removed demo application and moved directories to work with 'script/plugin install'.
- Updated README.markdown with better instructions.
- Added support for Workling/Starling.
- Added fail-safe mechanisms for Workling/Starling not being up.
- Added polling mechanism fail-safe for Juggernaut not being up.
- Added Javascript callbacks for onStatusUpdate, onBackEndType, onRemoteError, onServerError.

### June 28, 2008

- Initial Release.