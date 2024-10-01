# Ethernet-VHDL-Module

This repository contains VHDL implementations of Ethernet transmission(ethernet_tx) and reception (ethernet_rx) modules. These modules are designed to interface with standard Ethernet PHYs and can be integrated into FPGA designs for network communication.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Testbenches](#testbenches)
- [Next Steps](#next-steps)

## Overview

This project implements Ethernet transmission and reception in VHDL. The 'ethernet_tx' and 'ethernet_rx' modules handle the encoding and decoding of Ethernet frames. The frame data is stored in a bram. 

## Features

- **ethernet_tx.vhd**: Implements Ethernet frame transmission, handling the frame construction including headers and CRC calculation.
- **ethernet_rx.vhd**: Implements Ethernet frame reception, checking headers and CRC.

## Getting Started

### Prerequisites

To run or simulate these modules, you will need:
- **VHDL simulator**: ModelSim, GHDL, or any other simulator supporting VHDL.
- **FPGA development tools**: Such as Quartus Prime, Vivado, or Libero for synthesizing the design on hardware.

### Cloning the Repository

To get a copy of the project, clone the repository to your local machine using Git:

```bash

git clone https://github.com/ojakinlade/Ethernet-VHDL-Module.git

```

## Next steps

The next step for this project is to to use these Ethernet modules to interface with a GigE Vision camera. This will involve configuring the Ethernet interface to communicate with the camera, capturing the camera's data stream, and processing the frames received over the network.
