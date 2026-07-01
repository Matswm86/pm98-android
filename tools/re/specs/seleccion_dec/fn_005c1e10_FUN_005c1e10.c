// FUN_005c1e10  entry=005c1e10  size=157 bytes

bool __fastcall FUN_005c1e10(int *param_1)

{
  int iVar1;
  bool bVar2;
  
  bVar2 = false;
  if ((char)param_1[0xfb] == '\0') {
    if (((DAT_00674c64 != 0) && (*(char *)(DAT_00674c64 + 0x3ec) != '\0')) || (param_1[0x10] != 0))
    {
      iVar1 = FUN_005c1e10();
      bVar2 = iVar1 != 0;
    }
  }
  else {
    bVar2 = DAT_00674c74 == param_1;
    if ((!bVar2) &&
       ((DAT_00674c74 == (int *)0x0 ||
        (iVar1 = (**(code **)(*DAT_00674c74 + 0x108))(param_1), iVar1 != 0)))) {
      (**(code **)(*param_1 + 0x104))(DAT_00674c74);
      DAT_00674c74 = param_1;
      return true;
    }
  }
  return bVar2;
}


