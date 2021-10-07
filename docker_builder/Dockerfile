ARG IMAGE_VERSION=${IMAGE_VERSION:-20.04}
ARG REGISTRY_URI=${REGISTRY_URI:-}
ARG IMAGE_NAME=${IMAGE_NAME:-ubuntu}
FROM ${REGISTRY_URI}${IMAGE_NAME}:${IMAGE_VERSION} as base

# Enable headless (cli) package installs
ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		dkms \
		git \
		build-essential \
		debhelper \
		locales \
		tzdata \
		sudo \
		fakeroot \
		linux-headers-generic \
	; \
	rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

# Ensure at least the en_US.UTF-8 UTF-8 locale is available.
ARG LOCALE_ALREADY_SET
RUN \
	if [[ 'true' != "${LOCALE_ALREADY_SET:-}" && 'true' != "$((grep -o -E '^\s*en_US.UTF-8\s+UTF-8' /etc/locale.gen > /dev/null) && echo 'true' || echo 'false')" ]]; then \
		(echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen) && \
		locale-gen; \
	fi

# Default to UTF-8 encoding
ENV LC_ALL=en_US.UTF-8

# Set a timezone
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create or update a non-root user to match UID/GID.
ARG USERNAME=user
ARG USER_GID=1000
ARG USER_UID=1000
RUN \
	if [[ 'true' == "$(id -u '${USERNAME}' > /dev/null 2>&1 && echo 'true' || echo 'false')" ]]; then \
		# User exists, update if needed
		if [[ "${USER_GID}" != "$(id -G $USERNAME)" ]]; then \
			groupmod --gid "${USER_GID}" "${USERNAME}" && \
			usermod --gid "${USER_GID}" "${USERNAME}"; \
		fi; \
		if [[ "${USER_UID}" != "$(id -u '${USERNAME}')" ]]; then \
			usermod --uid "${USER_UID}" "${USERNAME}"; \
		fi; \
	else \
		# Create user
		if [[ 'automatic' == "${USER_GID}" ]]; then \
			groupadd "${USERNAME}"; \
		else \
			groupadd --gid "${USER_GID}" "${USERNAME}"; \
		fi; \
		if [[ 'automatic' == "${USER_UID}" ]]; then \
			useradd -s /bin/bash --gid "${USERNAME}" -m "${USERNAME}"; \
		else \
			useradd -s /bin/bash --uid "${USER_UID}" --gid "${USERNAME}" -m "${USERNAME}"; \
		fi; \
	fi

# Add add sudo support for non-root user
ARG EXISTING_NON_ROOT_USER
RUN \
	if [[ 'root' != "${USERNAME}" && "${EXISTING_NON_ROOT_USER:-}" != "${USERNAME}" ]]; then \
		ls -la /etc/sudoers && \
		mkdir -p /etc/sudoers.d && \
		(echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/"${USERNAME}") && \
		chmod 0440 /etc/sudoers.d/"${USERNAME}"; \
	fi

# enable upgrade periodic (daily) trigger and do upgrades
ARG UPDATE_TIMESTAMP
RUN (date > /etc/geneerik_apt_date) && \
    apt-get update -y && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -y && \
    apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# ensure working dir for mount exists
RUN mkdir -p /tmp/src && chmod 777 /tmp/src
WORKDIR /tmp/src

USER user

# Update the entrypoint. Note: CODECEPT_ARGS is no longer used
ENTRYPOINT [ "/bin/bash" ]
CMD [ "/tmp/src/install-driver.sh", "DebInstall" ]

# Versioning and docker metadata stuff
LABEL org.opencontainers.image.authors='Xcape, Inc. <support@xcapeinc.com>'
LABEL org.opencontainers.image.url='https://github.com/xcape-inc/rtl8814au'
LABEL org.opencontainers.image.documentation='https://github.com/xcape-inc/rtl8814au'
LABEL org.opencontainers.image.source='https://github.com/xcape-inc/rtl8814au.git'
LABEL org.opencontainers.image.vendor='Xcape, Inc.'
#LABEL org.opencontainers.image.licenses=''
LABEL org.opencontainers.image.title='ghcr.io/xcape-inc/dkms-build-env'
LABEL org.opencontainers.image.description="Docker image containing prerequisites to build and install dkms kernel modules via deb creation"

# set version stuff
ARG VERSION=unset
ARG LONG_FORM_VERSION=unset
USER 0
RUN (printf 'dkms build container' > /etc/xcape_product) && \
    (printf '%s' "${VERSION}" > /etc/xcape_version) && \
    (printf '%s' "${LONG_FORM_VERSION}" > /etc/xcape_version_long)
USER user

# run with docker-compose run --rm builder
