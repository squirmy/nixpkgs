{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

let
  stableVariant = {
    version = "5.15.33";
    suffix = "xanmod1";
    hash = "sha256-FOGjwkzAvautKsTKBMGfXMoRHeKgQtmK94hVKFdy2Ps=";
  };

  edgeVariant = {
    version = "5.17.2";
    suffix = "xanmod1";
    hash = "sha256-DK6yFZewqmr/BXFW5tqKXtWb1OLfqokZRQLOQxvBg6Q=";
  };

  xanmodKernelFor = { version, suffix, hash }: buildLinux (args // rec {
    inherit version;
    modDirVersion = "${version}-${suffix}";

    src = fetchFromGitHub {
      owner = "xanmod";
      repo = "linux";
      rev = modDirVersion;
      inherit hash;
    };

    structuredExtraConfig = with lib.kernel; {
      # removed options
      CFS_BANDWIDTH = lib.mkForce (option no);
      RT_GROUP_SCHED = lib.mkForce (option no);
      SCHED_AUTOGROUP = lib.mkForce (option no);

      # AMD P-state driver
      X86_AMD_PSTATE = yes;

      # Linux RNG framework
      LRNG = yes;

      # Paragon's NTFS3 driver
      NTFS3_FS = module;
      NTFS3_LZX_XPRESS = yes;
      NTFS3_FS_POSIX_ACL = yes;

      # Preemptive Full Tickless Kernel at 500Hz
      SCHED_CORE = lib.mkForce (option no);
      PREEMPT_VOLUNTARY = lib.mkForce no;
      PREEMPT = lib.mkForce yes;
      NO_HZ_FULL = yes;
      HZ_500 = yes;

      # Google's BBRv2 TCP congestion Control
      TCP_CONG_BBR2 = yes;
      DEFAULT_BBR2 = yes;

      # FQ-PIE Packet Scheduling
      NET_SCH_DEFAULT = yes;
      DEFAULT_FQ_PIE = yes;

      # Graysky's additional CPU optimizations
      CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

      # Futex WAIT_MULTIPLE implementation for Wine / Proton Fsync.
      FUTEX = yes;
      FUTEX_PI = yes;

      # WineSync driver for fast kernel-backed Wine
      WINESYNC = module;
    };

    extraMeta = {
      branch = lib.versions.majorMinor version;
      maintainers = with lib.maintainers; [ fortuneteller2k lovesegfault ];
      description = "Built with custom settings and new features built to provide a stable, responsive and smooth desktop experience";
      broken = stdenv.isAarch64;
    };
  } // (args.argsOverride or { }));
in
{
  stable = xanmodKernelFor stableVariant;
  edge = xanmodKernelFor edgeVariant;
}
