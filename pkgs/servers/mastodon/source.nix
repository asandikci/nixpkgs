# This file was generated by pkgs.mastodon.updateScript.
{ fetchgit, applyPatches }: let
  src = fetchgit {
    url = "https://github.com/tootsuite/mastodon.git";
    rev = "v3.4.6";
    sha256 = "1lg25m6wsnb7iabbn1vpvn85csv6ywyvcm0ji6d8iq7wwgyq77xs";
  };
in applyPatches {
  inherit src;
  patches = [ ];
}
