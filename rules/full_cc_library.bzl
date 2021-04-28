load(":cc_library_static.bzl", "cc_library_static")
load("@rules_cc//examples:experimental_cc_shared_library.bzl", "CcSharedLibraryInfo", "cc_shared_library")

def cc_library(
        name,
        srcs = [],
        hdrs = [],
        deps = [],
        transitive_export_deps = [],
        user_link_flags = [],
        copts = [],
        includes = [],
        linkopts = [],
        **kwargs):
    static_name = name + "_bp2build_cc_library_static"
    shared_name = name + "_bp2build_cc_library_shared"
    _cc_library_proxy(
        name = name,
        static = static_name,
        shared = shared_name,
    )

    cc_library_static(
        name = static_name,
        hdrs = hdrs,
        srcs = srcs,
        copts = copts,
        includes = includes,
        linkopts = linkopts,
        deps = deps,
    )

    cc_shared_library(
        name = shared_name,
        user_link_flags = user_link_flags,
        # b/184806113: Note this is a pretty a workaround so users don't have to
        # declare all transitive static deps used by this target.  It'd be great
        # if a shared library could declare a transitive exported static dep
        # instead of needing to declare each target transitively.
        static_deps = ["//:__subpackages__"],
        roots = [static_name + "_mainlib"],
    )

def _cc_library_proxy_impl(ctx):
    static_files = ctx.attr.static[DefaultInfo].files.to_list()
    shared_files = ctx.attr.shared[DefaultInfo].files.to_list()

    files = static_files + shared_files

    return [
        ctx.attr.shared[CcSharedLibraryInfo],
        ctx.attr.static[CcInfo],
        DefaultInfo(
            files = depset(direct = files),
            runfiles = ctx.runfiles(files = files),
        ),
    ]

_cc_library_proxy = rule(
    implementation = _cc_library_proxy_impl,
    attrs = {
        "shared": attr.label(mandatory = True, providers = [CcSharedLibraryInfo]),
        "static": attr.label(mandatory = True, providers = [CcInfo]),
    },
)
