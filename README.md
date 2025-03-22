## PhenoCam Installation Tool (PIT) development repository

This is the development repository of the [PhenoCam Installation Tool (v2)](https://github.com/bluegreen-labs/phenocam_installation_tool_v2/). If you are looking to configure your PhenoCam **YOU SHOULD NOT** use this repository. This repository is here for code development and legal liability reasons only. If you want to configure your PhenoCam use the following repository:

https://github.com/bluegreen-labs/phenocam_installation_tool_v2/

## For developers

Contributions are welcomed through pull requests. However, before doing so submit an issue to discuss the implementation of features - and if they align with the project. Some aspects of the code can't be changed and for bespoke software a separate consulting contract is needed.

To develop the code clone the code locally using:

```bash
git clone https://github.com/bluegreen-labs/phenocam_installation_tool_v2_dev.git
```

Then, uncomment [`line 11`](https://github.com/bluegreen-labs/phenocam_installation_tool_v2_dev/blob/7516040f4fc131d80f47e4b6aa148c50cad999d9/update_script.sh#L11) in the [`update_script.sh`](https://github.com/bluegreen-labs/phenocam_installation_tool_v2_dev/blob/main/update_script.sh) bash script. The script will exit before trying to deploy the code to the formal install repository.

It will put generate a `PIT.sh` file from the empty `PITe.sh` file, with the binary compressed data in the `files` directory appended to the end of the script. The file will be located in the project directory. You can use this `PIT.sh` script to test your added functionality. You will need to run the update script upon any change made to the code. You should never edit the `PIT.sh` file directly.

## Licensing and legal

> [!warning]
> Due to the Internet-of-Things (IoT) nature of the code of the Phenocam Installation Tool (PIT) BlueGreen Labs (BV), as a small software developer, is forced to open this code to avoid costly litigation under the European Commission [Cyber Resilience Act (CRA)](https://en.wikipedia.org/wiki/Digital_Services_Act) should a user mess up and a device is used as a mallware vector. This code is therefore open source under an AGPLv3 license.
>
> This means that you are free to use the software and inspect the code, to be in compliance with the CRA. BlueGreen Labs (BV) therefore will not accept any liability in case abuse facilitated through camera devices. Please consult BlueGreen Labs (BV) for custom applications. Please support small software developers/consultants.
