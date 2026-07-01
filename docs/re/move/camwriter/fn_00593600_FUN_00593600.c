// FUN_00593600  entry=00593600  size=1058 bytes

/* WARNING: Removing unreachable block (ram,0x00593706) */

undefined4 __fastcall FUN_00593600(int param_1)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  int *piVar4;
  undefined4 *puVar5;
  int *piVar6;
  int local_18 [4];
  int local_8;
  undefined4 local_4;
  
  *(undefined1 *)(param_1 + 0x180d) = 0;
  *(bool *)(param_1 + 0x1a1b) = *(int *)(*(int *)(param_1 + 0x468) + 0xfd0) != 0;
  *(bool *)(param_1 + 0x1a1c) = *(int *)(*(int *)(param_1 + 0x468) + 0xfd4) != 0;
  local_18[2] = 0xffff0000;
  local_4 = 0x3e80000;
  *(int *)(param_1 + 0x1984) = 3 - *(int *)(*(int *)(param_1 + 0x468) + 0xfd8);
  *(int *)(param_1 + 0x1988) = 2 - *(int *)(*(int *)(param_1 + 0x468) + 0xfdc);
  *(undefined4 *)(param_1 + 0x1a40) = 0xc66b14;
  local_8 = *(int *)(*(int *)(param_1 + 0x468) + 0x50) / 2;
  *(int *)(param_1 + 0x1820) = *(int *)(*(int *)(param_1 + 0x468) + 0x4c) / 2;
  *(int *)(param_1 + 0x1824) = local_8;
  local_18[3] = *(int *)(param_1 + 0x1820);
  iVar2 = -local_18[3];
  iVar3 = -local_8;
  local_18[0] = iVar2;
  local_18[1] = iVar3;
  if (-local_18[3] != local_18[3] && local_18[3] <= iVar2) {
    local_18[0] = local_18[3];
    local_18[3] = iVar2;
  }
  if (-local_8 != local_8 && local_8 <= iVar3) {
    local_18[1] = local_8;
    local_8 = iVar3;
  }
  local_4 = 0x3e80000;
  local_18[2] = 0xffff0000;
  piVar4 = local_18;
  piVar6 = (int *)(param_1 + 0x1828);
  for (iVar2 = 6; iVar2 != 0; iVar2 = iVar2 + -1) {
    *piVar6 = *piVar4;
    piVar4 = piVar4 + 1;
    piVar6 = piVar6 + 1;
  }
  *(undefined4 *)(param_1 + 0x194c) = 0x190000;
  *(int *)(param_1 + 0x1950) = *(int *)(param_1 + 0x1820) + 0x230000;
  *(int *)(param_1 + 0x1954) = *(int *)(param_1 + 0x1820) + 0xf0000;
  *(int *)(param_1 + 0x1958) = *(int *)(param_1 + 0x1820) + 0xf0000;
  *(int *)(param_1 + 0x195c) = *(int *)(param_1 + 0x1820) + 0x60000;
  *(int *)(param_1 + 0x1960) = *(int *)(param_1 + 0x1824) + 0x230000;
  *(int *)(param_1 + 0x1964) = *(int *)(param_1 + 0x1824) + 0xf0000;
  *(int *)(param_1 + 0x1968) = *(int *)(param_1 + 0x1824) + 0xf0000;
  *(int *)(param_1 + 0x196c) = *(int *)(param_1 + 0x1824) + 0x60000;
  *(int *)(param_1 + 0x1970) = *(int *)(param_1 + 0x1820) + 0xc0000;
  *(int *)(param_1 + 0x1974) = *(int *)(param_1 + 0x1820) + 0x40000;
  *(int *)(param_1 + 0x1978) = *(int *)(param_1 + 0x1824) + 0xc0000;
  *(int *)(param_1 + 0x197c) = *(int *)(param_1 + 0x1824) + 0x40000;
  *(undefined2 *)(param_1 + 0x181e) = 0x2000;
  *(undefined4 *)(param_1 + 0x1940) = 0xcccc;
  uVar1 = *(undefined4 *)(&DAT_00664060 + *(int *)(*(int *)(param_1 + 0x468) + 0xff4) * 4);
  *(undefined4 *)(param_1 + 0x1810) = 0;
  *(undefined4 *)(param_1 + 0x19ac) = uVar1;
  *(undefined4 *)(param_1 + 0x19a0) = 0;
  *(undefined4 *)(param_1 + 0x19a4) = 0;
  *(undefined4 *)(param_1 + 0x450) = 0;
  *(undefined4 *)(param_1 + 0x19a8) = 0;
  *(undefined1 *)(param_1 + 0x1a18) = 0;
  *(undefined1 *)(param_1 + 0x1a19) = 0;
  *(undefined1 *)(param_1 + 0x1808) = 1;
  *(undefined4 *)(param_1 + 0x1804) = 0x1e0000;
  *(int *)(param_1 + 0x1814) = -*(int *)(param_1 + 0x1960);
  *(undefined4 *)(param_1 + 0x1818) = 0xf0000;
  *(undefined1 *)(param_1 + 0x2882) = 0;
  FUN_005f5800(0x1e0000);
  local_18[2] = *(undefined4 *)(param_1 + 0x194c);
  local_18[0] = *(int *)(param_1 + 0x1950);
  local_18[1] = 0;
  FUN_005f5740(local_18);
  local_18[0] = 0;
  local_18[1] = 0;
  local_18[2] = 0;
  FUN_005f57a0(local_18);
  iVar3 = 2;
  *(undefined4 *)(param_1 + 0x19d0) = 0;
  *(undefined4 *)(param_1 + 0x19c4) = 0;
  *(undefined4 *)(param_1 + 0x19c0) = 0;
  *(undefined1 *)(param_1 + 0x1a20) = 0;
  *(undefined4 *)(param_1 + 0x19b8) = 0;
  *(undefined1 *)(param_1 + 0x1809) = 1;
  *(undefined4 *)(param_1 + 0x44c) = 2;
  *(undefined4 *)(param_1 + 0x448) = 2;
  iVar2 = FUN_005ec250();
  puVar5 = (undefined4 *)(param_1 + 0x480);
  iVar2 = (int)(iVar2 * 2 + (iVar2 * 2 >> 0x1f & 0x7fffU)) >> 0xf;
  *(int *)(param_1 + 0x19c8) = iVar2;
  *(int *)(param_1 + 0x45c) = iVar2;
  do {
    FUN_005b6ba0();
    *puVar5 = 0;
    puVar5[-1] = 0;
    puVar5[-2] = 0;
    puVar5 = puVar5 + 200;
    iVar3 = iVar3 + -1;
  } while (iVar3 != 0);
  *(undefined1 *)(param_1 + 0x1a1e) = 1;
  *(undefined4 *)(param_1 + 0x1a3c) = 0;
  *(undefined4 *)(param_1 + 0x1a38) = 0;
  *(undefined4 *)(param_1 + 0x1990) = 0;
  *(undefined4 *)(param_1 + 0x198c) = 0;
  *(undefined4 *)(param_1 + 0x454) = 0;
  *(undefined4 *)(param_1 + 0x1a2c) = 0;
  *(undefined4 *)(param_1 + 0x1a30) = 0;
  *(undefined4 *)(param_1 + 0x19b4) = 0;
  *(undefined4 *)(param_1 + 0x19b0) = 0;
  *(undefined1 *)(param_1 + 0x180e) = 1;
  FUN_00593a30();
  *(undefined4 *)(param_1 + 0x19e0) = 0;
  iVar2 = FUN_005ec250();
  *(int *)(param_1 + 0x19e4) = (int)(iVar2 * 900 + (iVar2 * 900 >> 0x1f & 0x7fffU)) >> 0xf;
  iVar2 = FUN_005ec250();
  *(int *)(param_1 + 0x19e8) = (int)(iVar2 * 0xe10 + (iVar2 * 0xe10 >> 0x1f & 0x7fffU)) >> 0xf;
  iVar2 = FUN_005ec250();
  *(undefined4 *)(param_1 + 0x19f0) = 0;
  iVar2 = ((int)(iVar2 * 0x960 + (iVar2 * 0x960 >> 0x1f & 0x7fffU)) >> 0xf) + 900;
  *(undefined4 *)(param_1 + 0x19f8) = 0;
  *(int *)(param_1 + 0x19ec) = iVar2;
  *(undefined4 *)(param_1 + 0x19f4) = 0;
  *(undefined4 *)(param_1 + 0x1a00) = 0;
  *(undefined4 *)(param_1 + 0x19fc) = 0;
  return CONCAT31((int3)((uint)iVar2 >> 8),1);
}


