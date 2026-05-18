{ pkgs, ... }: {
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-poi ];
    settings = {
      git_protocol = "https";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        bw = "repo view --web";
      };
      version = "1";
    };
  };
}
