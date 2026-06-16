// FUN_005e4670  entry=005e4670  size=348 bytes

int FUN_005e4670(LPCSTR param_1)

{
  LPSTR lpString2;
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  undefined4 local_234 [2];
  CHAR local_22c [32];
  CHAR local_20c [256];
  CHAR local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00621c06;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  lstrcpyA(local_20c,param_1);
  lpString2 = CharUpperA(local_20c);
  lstrcpyA(local_10c,lpString2);
  iVar3 = 0;
  local_234[0] = 0;
  local_4 = 0;
  lstrcpyA(local_22c,local_10c);
  local_4 = 1;
  iVar2 = DAT_006d3064 + -1;
  iVar4 = DAT_006d3064 / 2;
  if (-1 < iVar2) {
    do {
      if (DAT_006d3064 <= iVar2) break;
      iVar1 = lstrcmpA((LPCSTR)(DAT_006d3060 + 8 + iVar4 * 0x28),local_22c);
      if (iVar1 == 0) break;
      iVar1 = FUN_005e42b0(local_234);
      if (iVar1 == 0) {
        iVar2 = iVar4 + -1;
      }
      else {
        iVar3 = iVar4 + 1;
      }
      iVar4 = (iVar2 + 1 + iVar3) / 2;
    } while (iVar3 <= iVar2);
  }
  if (iVar4 < DAT_006d3064) {
    iVar3 = lstrcmpA((LPCSTR)(DAT_006d3060 + 8 + iVar4 * 0x28),local_22c);
    if (iVar3 == 0) goto LAB_005e4781;
  }
  iVar4 = -1;
LAB_005e4781:
  if ((iVar4 < 0) || (DAT_006d3064 <= iVar4)) {
    iVar3 = 0;
  }
  else {
    iVar3 = DAT_006d3060 + iVar4 * 0x28;
  }
  local_4 = 0xffffffff;
  thunk_FUN_005e0920();
  ExceptionList = local_c;
  return iVar3;
}


