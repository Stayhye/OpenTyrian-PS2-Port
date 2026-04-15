#!/bin/sh
IRX_DIR=$PS2SDK/iop/irx
BIN2C=$PS2SDK/bin/bin2c

$BIN2C $IRX_DIR/usbd.irx src/usbd_irx.c usbd_irx
$BIN2C $IRX_DIR/bdm.irx src/bdm_irx.c bdm_irx
$BIN2C $IRX_DIR/bdmfs_fatfs.irx src/bdmfs_fatfs_irx.c bdmfs_fatfs_irx
$BIN2C $IRX_DIR/usbmass_bd.irx src/usbmass_bd_irx.c usbmass_bd_irx
