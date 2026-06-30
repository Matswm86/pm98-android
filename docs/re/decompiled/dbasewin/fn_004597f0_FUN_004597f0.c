// FUN_004597f0  entry=004597f0  size=157 bytes

bool __fastcall FUN_004597f0(int *param_1)

{
  int iVar1;
  undefined3 extraout_var;
  int *piVar2;
  bool bVar3;
  
  bVar3 = false;
  if ((char)param_1[0xfb] == '\0') {
    if (((DAT_00501dac != (int *)0x0) && (piVar2 = DAT_00501dac, (char)DAT_00501dac[0xfb] != '\0'))
       || (piVar2 = (int *)param_1[0x10], piVar2 != (int *)0x0)) {
      bVar3 = FUN_004597f0(piVar2);
      bVar3 = CONCAT31(extraout_var,bVar3) != 0;
    }
  }
  else {
    bVar3 = DAT_00501dbc == param_1;
    if ((!bVar3) &&
       ((DAT_00501dbc == (int *)0x0 ||
        (iVar1 = (**(code **)(*DAT_00501dbc + 0x108))(param_1), iVar1 != 0)))) {
      (**(code **)(*param_1 + 0x104))(DAT_00501dbc);
      DAT_00501dbc = param_1;
      return true;
    }
  }
  return bVar3;
}


