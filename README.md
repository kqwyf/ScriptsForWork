# Scripts For Work

一些用于工作的脚本，其中一部分是用于包装slurm功能并提供其它方便功能的脚本。~~slurm也太难用了~~

作者不保证脚本中没有bug，**使用本仓库中脚本所发生的一切后果之责任由使用者承担。**

建议克隆本仓库后将仓库目录加入`PATH`环境变量中，以方便运行脚本。

## 脚本简介

本部分简要介绍各脚本功能并提供使用示例。脚本的完整说明可见各脚本的头部注释。

### slurm相关

- `submit`：无需编写sbatch批处理文件，通过命令行方便灵活地提交sbatch任务。
  - 适用场景：任务由单条命令启动（如shell脚本、Python脚本等），需要为所执行的命令指定若干种命令行参数分别提交，每次提交所需的资源也可能不同。任务不需要交互式运行。

    **目前不支持使用了slurm的array参数的任务，未来将改进。**
  - 使用时将生成的相关文件：
    - 在工作目录下创建`stdout`目录（可修改）并在其中存放任务的标准输出，以`任务ID.txt`方式命名。
    - 在工作目录下创建`stderr`目录（可修改）并在其中存放任务的标准错误，以`任务ID.txt`方式命名。
    - 在工作目录下创建`slurm`目录（可修改）并在其中存放任务的批处理文件，以`任务ID.txt`方式命名。
    - 在家目录下创建`.slurm_job_history`文件，在其中记录历史任务信息。
  - 使用前的预备步骤（非必需）：
    1. 修改脚本中的`config_dir`的值，使之指向你选定的一个配置文件目录。
    2. 在配置文件目录中创建配置文件（如`01-espnet.sh`），并在配置文件中指定默认配置。脚本将根据你的工作目录中包含的关键词确定以哪个配置文件的内容作为默认参数。

    有关配置文件更详细的说明，请参考脚本头部的注释。
  - 使用示例：
    - `submit -r run.sh -n prep_and_train -m 40G -c 2 -t 72:00:00 -- --stage 1 --stop_stage 6`

      本例中指定需要运行的脚本为`run.sh`，指定任务名为`prep_and_train`，指定使用内存上限为`40G`，指定线程数为`2`，指定时间限制为`72:00:00`，其余运行参数采用默认值（例如使用conda环境`espnet`）。在双横线`--`后为`run.sh`需要接受的参数，即`--stage 1 --stop_stage 6`。

      `submit`支持的所有参数可以直接运行`submit`查看，也可进入脚本查看。

      本例将生成以下sbatch批处理文件并提交：
      ```bash
      #!/bin/bash
      #SBATCH --job-name=prep_and_train
      #SBATCH --ntasks-per-node=1
      #SBATCH --partition=gpu
      #SBATCH --gres=gpu:1
      #SBATCH --qos=qd3
      #SBATCH --cpus-per-task=2
      #SBATCH --mem=40G
      #SBATCH --time=72:00:00
      #SBATCH --output=stdout/%j.txt
      #SBATCH --error=stderr/%j.txt

      module add anaconda/3
      module add cuda/10.1
      module add cudnn/7.6.1-cuda10.0
      module add imkl/2017.3.196
      module add gcc/5.4.0
      module add sox/14.4.2


      source activate espnet
      ./run.sh --stage 1 --stop_stage 6
      ```
    - `submit -r run.sh -n data_prep -p cpu -m 40G -c 2 -t 72:00:00 -- --stage 1 --stop_stage 4`

      本例相对上例，主要修改为指定提交队列为`cpu`。当提交队列为`cpu`时，脚本将自动删除`gres`参数，即不申请GPU资源。

      本例将生成以下sbatch批处理文件并提交：
      ```bash
      #!/bin/bash
      #SBATCH --job-name=data_prep
      #SBATCH --ntasks-per-node=1
      #SBATCH --partition=cpu
      
      #SBATCH --qos=qd3
      #SBATCH --cpus-per-task=2
      #SBATCH --mem=40G
      #SBATCH --time=72:00:00
      #SBATCH --output=stdout/%j.txt
      #SBATCH --error=stderr/%j.txt
      
      module add anaconda/3
      module add cuda/10.1
      module add cudnn/7.6.1-cuda10.0
      module add imkl/2017.3.196
      module add gcc/5.4.0
      module add sox/14.4.2
      
      
      source activate espnet
      ./run.sh --stage 1 --stop_stage 4
      ```
    - `submit -r python -n my_train -m 40G -c 2 -t 72:00:00 -- local/my_network/train.py --train_config conf/my_train.yaml`

      本例展示了如何执行不具有执行权限的脚本`local/my_network/train.py`。

- `cancel`：使用任务名或任务ID取消任务。附带bash和zsh的补全功能，可使用Tab补全任务名和任务ID。

  **目前脚本假定队列中不存在重名任务，故只取消第一个匹配任务。未来将改进为取消所有同名任务。**

  由于通常任务名与任务ID不会冲突，故本脚本没有特别约定优先匹配任务名或任务ID。
  - 补全配置：补全脚本在仓库的`completions`目录中。
    - 若使用bash，需要在bashrc中加入一行：
      ```
      source /path/to/cancel-completion.bash
      ```
      bash会读入该脚本（需重启bash）。
    - 若使用zsh，需要在zshrc中的**补全配置之前**加入一行：
      ```
      fpath=(/dir/to/completion/scripts $fpath)
      ```
      zsh会读入该目录下所有补全脚本（需重启zsh）。
  - 使用示例：
    - `cancel wsj_train wsj_prep 21807777`

      本例将取消任务名为`wsj_train`和`wsj_prep`的任务，以及任务ID为`21807777`的任务。
    - `cancel ALL`

      本例是脚本支持的特殊功能，即取消`squeue -u <your_name>`查询到的所有任务。
- `hist`：查看历史任务信息（通过家目录下的`.slurm_job_history`文件）。目前仅能输出任务ID、任务名和任务所在目录。
  - 使用示例：
    - `hist`

      本例显示最后10个被提交的任务。
    - `hist 50`

      本例显示最后50个被提交的任务。
- `out`：查看当前工作目录下最新被修改的标准输出文件（默认使用vim，可修改）。目前仅支持查看`stdout`目录下的输出文件，未来将加入读取`submit`相关配置的功能。
  - 使用示例：
    - `out`
- `err`：查看当前工作目录下最新被修改的标准错误文件（默认使用vim，可修改）。目前仅支持查看`stderr`目录下的输出文件，未来将加入读取`submit`相关配置的功能。
  - 使用示例：
    - `err`

### 其它

- `autoconnect`（用于本地主机）：本脚本（以及配套的`send`、`recv`脚本）的主要目的为在保持安全性的同时，快速进行登录服务器时的身份验证。

  支持使用明文密码、密文密码（以私钥加密，每次登录时临时解密）、私钥，以及用户自定义方式进行身份验证。
  - 适用场景：
    - 你有数台服务器需要经常登录。
    - 服务器禁用了公私钥验证策略，仅允许密码验证方式，但每次输入密码十分繁琐。
  - 依赖：本脚本依赖`expect`程序进行命令行自动操作。绝大多数Linux发行版的软件仓库中都包含该软件包。
  - 使用前的预备步骤：
    1. 在脚本头部注释后的`config_dir`处设置配置文件目录。
    2. 在设定的目录中编写配置文件，如`sz.sh`。配置文件模板见本仓库`hosts`目录下的`default.sh`文件。建议在配置文件目录中保留一个`default.sh`文件，并通过复制模板建立新配置。脚本将以`default.sh`中的配置为基础，并读取命令行指定的配置文件以覆盖`default.sh`的配置。

    建议不要删除配置文件中已有的变量，但可以随意增加新变量（以方便自定义`_custom_ssh`等函数）。
  - 使用密文密码的准备步骤（以`gpg`工具为例，配置文件模板中已附带解密函数，无需自行编写）：
    1. 执行`gpg --gen-key`命令，并根据提示生成一个密钥对。生成过程中需要为密钥设置密码，如你不想在自动登录时输入密码，可留空。假设你填写的姓名为`Foo Bar`。
    2. 新建文件`pw.txt`并写入你的ssh登录密码，然后执行`gpg --encrypt -r "Foo Bar" pw.txt`进行加密，生成的加密文件为`pw.txt.gpg`。记得在生成加密文件后删除`pw.txt`！
    3. 将生成的`pw.txt.gpg`放置在适当目录下，修改为适当的文件名，然后将该文件路径填入配置文件中的`password_file`字段即可。若今后还有其它需加密的密码，可跳过生成密钥对步骤。

    若你希望使用其它加/解密方式，可自行加密`pw.txt`，并在配置文件中自定义`_decrypt_password`函数。

    提示：`gpg`工具附带身份验证缓存功能。若你为密钥设置了密码，则仅第一次使用需要输入密码，之后直到你在本机注销登录之前都不需要再次输入密码。
  - 使用示例：
    - `autoconnect sz`

      本例中脚本将自动读取配置文件目录下的`sz.sh`配置并连接对应服务器。
  - 推荐附加配置：
    - 在你使用的shell的配置文件中通过alias为你常用的服务器加入快速登录命令，如：
      ```bash
      alias sz="autoconnect sz"
      ```
    - 对于苏州超算，只需对`expect`脚本稍加改动即可自动登录某一调试机。例如作者为每一调试机都设置了单独的`autoconnect`配置。
  - **提示**：由于脚本中涉及分支过多，难以一一测试，用户若使用中遇到问题，可及时发起issue。
- `send`（用于本地主机）：与`autoconnect`脚本类似，用于快速进行身份验证并向服务器发送（上传）文件。在配置文件中指定远程目录，所有上传文件均会被上传至这一目录。

  支持scp、sftp及用户自定义传输方式。
  - 使用前需按照`autoconnect`的预备步骤进行配置。本脚本与`autoconnect`共享配置文件。
  - 依赖：本脚本依赖`expect`程序进行命令行自动操作。绝大多数Linux发行版的软件仓库中都包含该软件包。
  - 使用示例：
    - `send sz a.txt foo/bar.tgz`

      本例中脚本向sz服务器上传了`a.txt`与`foo/bar.tgz`两个文件。
  - **提示**：由于脚本中涉及分支过多，难以一一测试，用户若使用中遇到问题，可及时发起issue。
- `recv`（用于本地主机）：与`send`脚本类似，用于快速进行身份验证并从服务器接收（下载）文件。在配置文件中指定远程目录，即可使用相对路径下载远程文件。远程文件将自动下载至shell当前所在目录。

  支持scp、sftp及用户自定义传输方式。
  - 使用前需按照`autoconnect`的预备步骤进行配置。本脚本与`autoconnect`共享配置文件。
  - 依赖：本脚本依赖`expect`程序进行命令行自动操作。绝大多数Linux发行版的软件仓库中都包含该软件包。
  - 使用示例：
    - `recv sz a.txt foo/bar.tgz`

      本例中脚本从sz服务器下载了`a.txt`与`foo/bar.tgz`两个文件。
  - **提示**：由于脚本中涉及分支过多，难以一一测试，用户若使用中遇到问题，可及时发起issue。
- `upload`（用于本地主机）：将本地目录镜像至远程主机。在配置文件中指定本地目录与远程目录的映射关系以及需要忽略的文件和目录后，即可进行镜像。一次镜像后再做修改时，可以增量更新。

  目前使用程序`lftp`完成镜像操作，支持sftp等协议，也支持用户自定义镜像方式。

  **由于sftp协议自身的限制，软链接无法被上传。**

  指定本地目录后，若在本地目录的子目录中执行脚本，则仅会镜像本地子目录中的内容到远程对应子目录中。
  - 使用前需按照`autoconnect`的预备步骤进行配置。本脚本与`autoconnect`共享配置文件。
  - 依赖：本脚本依赖`lftp`程序进行镜像操作。绝大多数Linux发行版的软件仓库中都包含该软件包。
  - 使用示例：
    - `upload sz`

      本例中脚本将当前所在目录同步至远程（仅同步新的修改）。
- `download`（用于本地主机）：将对应本地当前目录的远程目录镜像至本地。在配置文件中指定本地目录与远程目录的映射关系以及需要忽略的文件和目录后，即可进行镜像。一次镜像后再做修改时，可以增量更新。

  目前使用程序`lftp`完成镜像操作，支持sftp等协议，也支持用户自定义镜像方式。

  指定本地目录后，若在本地目录的子目录中执行脚本，则仅会镜像远程子目录中的内容到本地对应子目录中。
  - 使用前需按照`autoconnect`的预备步骤进行配置。本脚本与`autoconnect`共享配置文件。
  - 依赖：本脚本依赖`lftp`程序进行镜像操作。绝大多数Linux发行版的软件仓库中都包含该软件包。
  - 使用示例：
    - `download sz`

      本例中脚本将对应当前本地所在目录的远程目录同步至本地（仅同步新的修改）。
- `app`：为文件或文件夹添加（以点号分隔的）后缀名。语法：`app 后缀名 文件1 文件2 ...`。本脚本常用于备份实验目录或日志文件。
  - 使用示例：
    - `app backup exp/train_5a exp/train_5b`

      本例将目录`exp/train_5a`重命名为`exp/train_5a.backup`，将目录`exp/train_5b`重命名为`exp/train_5b.backup`。
    - `app -f backup exp/train_5a exp/train_5b`

      本例相对于上例，加入了`-f`参数，即`--force`，如目标文件（夹）已存在，将被覆盖。
- `rma`：删除文件或文件夹的最后一个（以点号分隔的）后缀名。若文件无后缀名，则忽略。
  - 使用示例：
    - `rma exp/train_5a.backup exp/train_5b.abc.backup`

      本例将目录`exp/train_5a.backup`重命名为`exp/train_5a`，将目录`exp/train_5b.abc.backup`重命名为`exp/train_5b.abc`。

