# brudi

When it comes to backup-creation there are several solutions to use.  
In general everybody's doing some sort of `dump` or `tar` and backing up the results incremental with [`restic`](https://github.com/restic/restic) or similar programs.

This is why `brudi` was born. `brudi` supports several backup-methods and is configurable by a simple `yaml` file.
The advantage of `brudi` is, that you can create a backup of a source of your choice and save it with `restic` aftwards in one step.
Under the hood, `brudi` uses the given binaries like `mysqldump`, `mongodump`, `tar` or `restic`.

Using `brudi` will save you from finding yourself writing bash-scripts to create your backups.

## Table of contents

- [Usage](#usage)
  - [CLI](#cli)
  - [Configuration](#configuration)
    - [Sources](#sources)
      - [Tar](#tar)
      - [MySQLDump](#mysqldump)
      - [MongoDump](#mongodump)
    - [Restic](#restic)
    - [Sensitive data: Environment variables](#sensitive-data--environment-variables)
- [Featurestate](#featurestate)
  - [Source backup methods](#source-backup-methods)
  - [Incremental backup of the source backups](#incremental-backup-of-the-source-backups)

## Usage

### CLI

In order to use the `brudi`-binary on your local machine or a remote server of your choice, ensure you have the required tools installed.

- `mongodump` (required when running `brudi mongodump`)
- `mysqldump` (required when running `brudi mysqldump`)
- `tar` (required when running `brudi tar`)
- `restic` (required when running `brudi --restic`)

```shell
$ brudi --help

Easy, incremental and encrypted backup creation for different backends (file, mongoDB, mysql, etc.)
After creating your desired tar- or dump-file, `brudi` backs up the result with restic - if you want to.

Usage:
  brudi [command]

Available Commands:
  help        Help about any command
  mongodump   Creates a mongodump of your desired server
  mysqldump   Creates a mysqldump of your desired server
  tar         Creates a tar archive of your desired paths
  version     Print the version number of brudi

Flags:
      --cleanup         cleanup backup files afterwards
  -c, --config string   config file (default is ${HOME}/.brudi.yaml)
  -h, --help            help for brudi
      --restic          backup result with restic and push it to s3
      --version         version for brudi

Use "brudi [command] --help" for more information about a command.
```

### Docker

In case you don't want to install additional tools, you can also use `brudi` inside docker:

`docker run --rm -v ${HOME}/.brudi.yml:/home/brudi/.brudi.yml quay.io/mittwald/brudi mongodump --restic --cleanup`

The docker-image comes with all required binaries.

### Configuration

As already mentioned, `brudi` is configured via `.yaml`. The default path for this file is `${HOME}/.brudi.yaml`, but it's adjustable via `-c` or `--config`.
Since the configuration provided by the `.yaml`-file is mapped to the corresponding CLI-flags, you can adjust literally every parameter of your source backup.  
Therefore you can simply refer to the official documentation for explanations on the available flags:

- [`tar`](https://www.gnu.org/software/tar/manual/html_section/tar_22.html)
- [`mongodump`](https://docs.mongodb.com/manual/reference/program/mongodump/#options)
- [`mysqldump`](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html#mysqldump-option-summary)

Every source has a an `additionalArgs`-key which's value is an array of strings. The value of this key is appended to the command, generated by `brudi`.
Even though `brudi` should support all cli-flags to be configured via the `.yaml`-file, there may be flags which are not.  
In this case, use the `additionalArgs`-key.

#### Sources

##### Tar

```yaml
tar:
  options:
    flags:
      create: true
      gzip: true
      file: /tmp/test.tar.gz
    additionalArgs: []
    paths:
      - /tmp/testfile
  hostName: autoGeneratedIfEmpty
```

Running: `brudi tar -c ${HOME}/.brudi.yml --cleanup`

Becomes the following command:  
`tar -c -z -f /tmp/test.tar.gz /tmp/testfile`  

All available flags to be set in the `.yaml`-configuration can be found [here](pkg/source/tar/cli.go#L7).

##### MySQLDump

```yaml
mysqldump:
  options:
    flags:
      host: 127.0.0.1
      port: 3306
      password: mysqlroot
      user: root
      opt: true
      allDatabases: true
      resultFile: /tmp/test.sqldump
    additionalArgs: []
```

Running: `brudi mysqldump -c ${HOME}/.brudi.yml --cleanup`

Becomes the following command:  
`mysqldump --all-databases --host=127.0.0.1 --opt --password=mysqlroot --port=3306 --result-file=/tmp/test.sqldump --user=root`  

All available flags to be set in the `.yaml`-configuration can be found [here](pkg/source/mysqldump/cli.go#L7).

##### MongoDump

```yaml
mongodump:
  options:
    flags:
      host: 127.0.0.1
      port: 27017
      gzip: true
      archive: /tmp/dump.tar.gz
    additionalArgs: []
```

Running: `brudi mongodump -c ${HOME}/.brudi.yml --cleanup`

Becomes the following command:  
`mongodump --host=127.0.0.1 --port=27017 --username=root --password=mongodbroot --gzip --archive=/tmp/dump.tar.gz`  

All available flags to be set in the `.yaml`-configuration can be found [here](pkg/source/mongodump/cli.go#L7).

#### Restic

In case you're running your backup with the `--restic`-flag, you need to provide a [valid configuration for restic](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html).  
You can either configure `restic` via `brudi`s `.yaml`-configuration, or via the [environment variables](https://restic.readthedocs.io/en/latest/040_backup.html#environment-variables) used by `restic`.  

For now, it's only possible to use `restic` with an `S3` compatible backend or any other backend compatible with the env `RESTIC_REPOSITORY`.

```yaml
restic:
  bucketName: "my.s3.bucket"
  host: "filled with hostname of backup"
  accessKeyID: ""
  secretAccessKey: ""
  region: "your s3 endpoint"
  repository: "auto generated from bucketName and region if empty"
  password: "required"
```

#### Sensitive data: Environment variables

In case you don't want to provide data directly in the `.yaml`-file, e.g. sensitive data like passwords, you can use environment-variables.
Each key of the configuration is overwritable via environment-variables. Your variable must specify the whole path to a key, seperated by `_`.  
For example, given this `.yaml`:

```yaml
mongodump:
  options:
    flags:
      username: "" # we will override this by env
      password: "" # we will override this by env
      host: 127.0.0.1
      port: 27017
      gzip: true
      archive: /tmp/dump.tar.gz
```

Set your env's:

```shell
export MONGODUMP_OPTIONS_FLAGS_USERNAME="root"
export MONGODUMP_OPTIONS_FLAGS_PASSWORD="mongodbroot"
```

Same goes for restic. Given this example `.yaml`:

```yaml
restic:
  repository: "s3:s3.eu-central-1.amazonaws.com/your.s3.bucket/repo"
  accessKeyID: "" # set by env
  secretAccessKey: "" # set by env
```

Override by env's:

```shell
export RESTIC_SECRETACCESSKEY="topSecret"
export RESTIC_ACCESSKEYID="secret"
```

As soon as a variable for a key exists in your environment, the value of this environment-variable is used in favour of your `.yaml`-config.

## Featurestate

### Source backup methods

- [x] `mysqldump`
- [x] `mongodump`
- [x] `tar`

### Incremental backup of the source backups

- [x] `restic`
  - [ ] `commands`
    - [x] `restic backup`
    - [ ] `restic forget`
  - [x] `storage`
    - [x] `s3`
