# actions.publish-container

A GitHub Action that builds and publishes containers to a container registry with standardized tagging and customizable summaries.

[![Build](https://github.com/spritely/actions.publish-container/actions/workflows/build.yml/badge.svg)](https://github.com/spritely/actions.publish-container/actions/workflows/build.yml)

## Features

- Publishes images to any container registry (GitHub Packages, Docker Hub, etc.)
- Supports multiple image names to be built and published from the same source
- Generates customizable Markdown summaries with build details
- Supports build-time secrets for secure CI/CD pipelines

## Usage

```yaml
- uses: spritely/actions.publish-container@v0.1
  with:
    registryHost: ghcr.io
    registryUsername: ${{ github.actor }}
    registryPassword: ${{ secrets.GITHUB_TOKEN }}
    imageNames: ghcr.io/myorg/myimage
    version: 1.2.3
```

### Complete Example with Custom Template

```yaml
- name: Build and publish container
  id: publish
  uses: spritely/actions.publish-container@v1
  with:
    registryHost: ghcr.io
    registryUsername: ${{ github.actor }}
    registryPassword: ${{ secrets.GITHUB_TOKEN }}
    imageNames: |
      ghcr.io/${{ github.repository }}/api
      ghcr.io/${{ github.repository }}/web
    version: 1.2.3
    context: ./
    dockerfile: ./Dockerfile
    containerSecrets: |
      NPM_TOKEN=${{ secrets.NPM_TOKEN }}
      GIT_AUTH_TOKEN=${{ secrets.GIT_AUTH_TOKEN }}
    messageTemplate: |
      ## 🚀 Container Build Results
      
      **Version:** {{ version }}
      **Built by:** {{ owner }}/{{ repo }}
      
      ### 📦 Images
      {% for image in images %}
      - `{{ image }}` 🔄
      {% endfor %}
      
      ### 🏷️ Tags
      | Tag | Full Name |
      |-----|-----------|
      {% for tag in tags %}
      | `{{ tag }}` | `{{ registry }}/${{ github.repository }}:{{ tag }}` |
      {% endfor %}
```

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `registryHost` | The host of the container registry to push to | Yes | |
| `registryUsername` | The username to use to authenticate with the container registry | Yes | |
| `registryPassword` | The token to use to authenticate with the container registry | Yes | |
| `imageNames` | The names of the images to tag and publish | Yes | |
| `version` | The semantic version of the image to tag and publish | Yes | |
| `containerSecrets` | The secrets to use when building the container | No | "" |
| `context` | The context to use when building | No | `${{ github.workspace }}` |
| `dockerfile` | The dockerfile to build | No | `${{ github.workspace }}/Dockerfile` |
| `writeSummary` | Whether to write the summary to GitHub's step summary | No | "true" |
| `messageTemplate` | Jinja2 markdown template used to generate the build summary | No | Default template |

### Default Message Template

```markdown
# Created Containers

{% for image in images %}
- Image {{ image }} pushed to {{ registry }}.
{% endfor %}

## Tags
{% for tag in tags %}
- {{ tag }}
{% endfor %}

## Labels
{% for key, value in labels.items() %}
- **{{ key }}**: {{ value }}
{% endfor %}
```

## Outputs

| Name | Description |
|------|-------------|
| `summary` | Markdown summary of the build results |

## Template Variables

The following variables are available in custom message templates:

| Variable | Description |
|----------|-------------|
| `version` | The semantic version of the image |
| `owner` | The owner of the repository |
| `repo` | The repository name |
| `registry` | The registry host |
| `images` | Array of image names being published |
| `tags` | Array of tags generated for the images |
| `labels` | Object containing all labels applied to the images |

## Automatically Generated Tags

This action automatically generates the following tags for each image:

- `<version>` - Full semantic version (e.g., `1.2.3`)
- `<major>.<minor>` - Major and minor version (e.g., `1.2`)
- `<major>` - Major version only (e.g., `1`)
- Branch tags for non-pull request builds (e.g., `main-latest`)

## License

[Apache License, Version 2.0](LICENSE)
