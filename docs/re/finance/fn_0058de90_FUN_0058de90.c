// FUN_0058de90  entry=0058de90  size=122 bytes

LPSTR FUN_0058de90(LPSTR param_1,uint param_2)

{
  undefined *puVar1;
  uint uVar2;
  char local_100 [256];
  
  uVar2 = param_2 % 10;
  if (uVar2 == 1) {
    if (param_2 != 0xb) {
      puVar1 = &DAT_00663c28;
      goto LAB_0058ded8;
    }
  }
  else if (uVar2 == 2) {
    if (param_2 != 0xc) {
      puVar1 = &DAT_00663c2c;
      goto LAB_0058ded8;
    }
  }
  else if ((uVar2 == 3) && (param_2 != 0xd)) {
    puVar1 = &DAT_00663c30;
    goto LAB_0058ded8;
  }
  puVar1 = &DAT_00663c24;
LAB_0058ded8:
  sprintf(local_100,&DAT_00663c1c,param_2,puVar1);
  lstrcpyA(param_1,local_100);
  return param_1;
}


