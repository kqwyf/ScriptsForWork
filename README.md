# Scripts For Work

一些用于工作的脚本，其中一部分是用于包装slurm功能并提供其它方便功能的脚本。~~slurm也太难用了~~

作者不保证脚本中没有bug，**使用本仓库中脚本所发生的一切后果之责任由使用者承担。**

建议克隆本仓库后将仓库目录加入`PATH`环境变量中，以方便运行脚本。

## 脚本简介

本部分简要介绍各脚本功能并提供使用示例。脚本的完整说明可见各脚本的头部注释。

### slurm相关

- `submit`：无需编写sbatch批处理文件，通过命令行方便灵活地提交sbatch任务。
  - 适用场景：任务由单条命令启动（如shell脚本、Python脚本等），需要为所执行的命令指定若干种命令行参数分别提交，每次提交所需的资源也可能不同。任务不需要交互式运行。

    **目前不支持多卡任务，未来将改进。**
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

