// FUN_005baca0  entry=005baca0  size=184 bytes
// callers/callees expanded one level from seeds

int * __fastcall FUN_005baca0(int *param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int *piVar4;
  int iVar5;
  
  *(undefined1 *)((int)param_1 + 0x32d9) = 0;
  *(undefined1 *)(param_1 + 0xcb6) = 0;
  iVar5 = 0x168;
  piVar4 = param_1;
  do {
    iVar1 = FUN_005ec250();
    iVar2 = FUN_005ec250();
    iVar3 = FUN_005ec250();
    *piVar4 = (int)(iVar1 * 0x1000 + (iVar1 * 0x1000 >> 0x1f & 0x7fU)) >> 7;
    piVar4[1] = (int)(iVar2 * 0x1000 + (iVar2 * 0x1000 >> 0x1f & 0x7fU)) >> 7;
    iVar5 = iVar5 + -1;
    piVar4[2] = (int)(iVar3 * 0x1000 + (iVar3 * 0x1000 >> 0x1f & 0x7fU)) >> 7;
    piVar4 = piVar4 + 3;
  } while (iVar5 != 0);
  iVar5 = 0xf0;
  piVar4 = param_1 + 0x52b;
  do {
    piVar4[-1] = 0x3f000000;
    *piVar4 = 0x3f800000;
    piVar4[1] = -0x40000001;
    piVar4[2] = 0;
    piVar4[3] = 0x3f7e0000;
    piVar4[4] = 0x3f7e0000;
    piVar4 = piVar4 + 8;
    iVar5 = iVar5 + -1;
  } while (iVar5 != 0);
  param_1[0xcb5] = 0;
  param_1[0xca8] = 0;
  return param_1;
}


