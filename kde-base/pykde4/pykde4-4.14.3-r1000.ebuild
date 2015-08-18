# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_ABI_TYPE="multiple"
PYTHON_DEPEND="<<[threads]>>"
PYTHON_RESTRICTED_ABIS="*-jython *-pypy"
OPENGL_REQUIRED="always"

inherit eutils kde4-base multilib portability python toolchain-funcs

DESCRIPTION="Python bindings for KDE4"
HOMEPAGE="http://techbase.kde.org/Development/Languages/Python"

KEYWORDS="*"
IUSE="akonadi debug doc examples"

RDEPEND="
	$(python_abi_depend ">=dev-python/PyQt4-4.9.5:0=[X,dbus,declarative,script,sql,svg,webkit]")
	$(python_abi_depend ">=dev-python/sip-4.14:0=")
	$(add_kdebase_dep kdelibs 'opengl')
	akonadi? ( $(add_kdebase_dep kdepimlibs) )
"
DEPEND="${RDEPEND}
	sys-devel/libtool
"

pkg_setup() {
	python_pkg_setup
	kde4-base_pkg_setup

	have_python2=false

	scan_python_versions() {
		[[ ${PYTHON_ABI} == 2.* ]] && have_python2=true
		:
	}
	python_execute_function -q scan_python_versions
	if ! ${have_python2}; then
		ewarn "You do not have a Python 2 version selected."
		ewarn "kpythonpluginfactory will not be built"
	fi
}

src_prepare() {
	kde4-base_src_prepare

	if ! use examples; then
		sed -e '/^ADD_SUBDIRECTORY(examples)/s/^/# DISABLED /' -i CMakeLists.txt \
			|| die "Failed to disable examples"
	fi

	# See bug 322351
	use arm && epatch "${FILESDIR}/${PN}-4.14.0-arm-sip.patch"

	sed -i -e 's/kpythonpluginfactory /kpython${PYTHON_SHORT_VERSION}pluginfactory /g' kpythonpluginfactory/CMakeLists.txt

	if ${have_python2}; then
		mkdir -p "${WORKDIR}/wrapper" || die "failed to copy wrapper"
		cp "${FILESDIR}/kpythonpluginfactorywrapper.c-r1" "${WORKDIR}/wrapper/kpythonpluginfactorywrapper.c" || die "failed to copy wrapper"
	fi

	# Disable versioning of pykdeuic4 symlink to avoid collision with versioning performed by python_merge_intermediate_installation_images().
	sed -e 's/^set(_uic_name "pykdeuic4-${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}")$/set(_uic_name "pykdeuic4")/' -i tools/pykdeuic4/CMakeLists.txt
}

src_configure() {
	configuration() {
		local mycmakeargs=(
			-DWITH_PolkitQt=OFF
			-DWITH_QScintilla=OFF
			-DWITH_Nepomuk=OFF
			-DWITH_Soprano=OFF
			$(cmake-utils_use_with akonadi KdepimLibs)
			-DPYTHON_EXECUTABLE=$(PYTHON -a)
			-DPYKDEUIC4_ALTINSTALL=TRUE
		)
		local BUILD_DIR=${S}_build-${PYTHON_ABI}
		kde4-base_src_configure
	}

	python_execute_function configuration
}

src_compile() {
	compilation() {
		local BUILD_DIR=${S}_build-${PYTHON_ABI}
		kde4-base_src_compile
	}
	python_execute_function compilation

	if ${have_python2}; then
		pushd "${WORKDIR}/wrapper" > /dev/null
		python_execute libtool --tag=CC --mode=compile $(tc-getCC) \
			-shared \
			${CFLAGS} ${CPPFLAGS} \
			-DEPREFIX="\"${EPREFIX}\"" \
			-DPLUGIN_DIR="\"/usr/$(get_libdir)/kde4\"" -c \
			-o kpythonpluginfactorywrapper.lo \
			kpythonpluginfactorywrapper.c
		python_execute libtool --tag=CC --mode=link $(tc-getCC) \
			-shared -module -avoid-version \
			${CFLAGS} ${LDFLAGS} \
			-o kpythonpluginfactory.la \
			-rpath "${EPREFIX}/usr/$(get_libdir)/kde4" \
			kpythonpluginfactorywrapper.lo \
			$(dlopen_lib)
		popd > /dev/null
	fi
}

src_test() {
	:
}

src_install() {
	installation() {
		cd "${S}_build-${PYTHON_ABI}"
		emake DESTDIR="${T}/images/${PYTHON_ABI}" install
	}
	python_execute_function installation
	python_merge_intermediate_installation_images "${T}/images"

	# As we don't call the eclass's src_install, we have to install the docs manually
	DOCS=("${S}"/{AUTHORS,NEWS,README})
	use doc && HTML_DOCS=("${S}/docs/html/")
	einstalldocs

	if ${have_python2}; then
		pushd "${WORKDIR}/wrapper" > /dev/null
		python_execute libtool --mode=install install kpythonpluginfactory.la "${ED}/usr/$(get_libdir)/kde4/kpythonpluginfactory.la"
		rm "${ED}/usr/$(get_libdir)/kde4/kpythonpluginfactory.la"
		popd > /dev/null
	fi
}

pkg_postinst() {
	kde4-base_pkg_postinst

	python_byte-compile_modules PyKDE4 PyQt4/uic/pykdeuic4.py PyQt4/uic/widget-plugins/kde4.py

	if use examples; then
		echo
		elog "PyKDE4 examples have been installed to"
		elog "${EPREFIX}/usr/share/apps/${PN}/examples"
		echo
	fi
}

pkg_postrm() {
	kde4-base_pkg_postrm

	python_clean_byte-compiled_modules PyKDE4 PyQt4/uic/pykdeuic4.py PyQt4/uic/widget-plugins/kde4.py
}
