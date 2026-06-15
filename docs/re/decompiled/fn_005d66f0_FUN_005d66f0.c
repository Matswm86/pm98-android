// FUN_005d66f0  entry=005d66f0  size=291 bytes
// callers/callees expanded one level from seeds

undefined4 __thiscall FUN_005d66f0(int *param_1,int *param_2,ushort param_3)

{
  undefined4 uVar1;
  byte bVar2;
  bool bVar3;
  char cVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  undefined1 uVar8;
  undefined4 *puVar9;
  int *piVar10;
  int *piVar11;
  
  uVar8 = 0;
  if ((param_1[1] == 0) && (*param_1 == 0)) {
    bVar3 = false;
  }
  else {
    bVar3 = true;
  }
  if (((!bVar3) || (param_1[5] != param_2[5])) || (param_1[6] != param_2[6])) {
    FUN_005c9a30(param_2[5],param_2[6],8,0,0xffffffff);
  }
  if ((*param_1 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
    iVar5 = 0;
  }
  else {
    iVar5 = 1;
  }
  if ((char)iVar5 != '\0') {
    if ((*param_2 == 0) && (cVar4 = FUN_005cb2b0(), cVar4 == '\0')) {
      iVar5 = 0;
    }
    else {
      iVar5 = 1;
    }
    if ((char)iVar5 != '\0') {
      puVar9 = (undefined4 *)*param_2;
      piVar11 = (int *)*param_1;
      iVar6 = (int)(param_1[6] * param_1[7] + (param_1[6] * param_1[7] >> 0x1f & 3U)) >> 2;
      iVar7 = iVar6;
      piVar10 = piVar11;
      do {
        uVar1 = *puVar9;
        puVar9 = puVar9 + 1;
        bVar2 = -((char)((uint)uVar1 >> 0x10) != '\0');
        iVar5 = CONCAT22((ushort)bVar2 |
                         (ushort)(((uint)CONCAT11(bVar2,-((char)((uint)uVar1 >> 0x18) != '\0')) <<
                                  0x18) >> 0x10),
                         CONCAT11(-((char)((uint)uVar1 >> 8) != '\0'),-((char)uVar1 != '\0')));
        iVar7 = iVar7 + -1;
        *piVar10 = iVar5;
        piVar10 = piVar10 + 1;
      } while (iVar7 != 0);
      if (param_3 != 0x100) {
        do {
          iVar5 = *piVar11;
          iVar5 = CONCAT31((int3)(CONCAT22((ushort)((ushort)(byte)((uint)iVar5 >> 0x10) *
                                                   (param_3 & 0xff)) >> 8 |
                                           (ushort)(((uint)(byte)((ushort)((ushort)(byte)((uint)
                                                  iVar5 >> 0x18) * (param_3 & 0xff)) >> 8) << 0x18)
                                                  >> 0x10),
                                           ((ushort)((uint)iVar5 >> 8) & 0xff) * (param_3 & 0xff))
                                 >> 8),
                           (char)((ushort)((ushort)((uint)(iVar5 << 0x18) >> 0x18) *
                                          (param_3 & 0xff)) >> 8));
          iVar6 = iVar6 + -1;
          *piVar11 = iVar5;
          piVar11 = piVar11 + 1;
        } while (iVar6 != 0);
      }
      uVar8 = 1;
    }
  }
  return CONCAT31((int3)((uint)iVar5 >> 8),uVar8);
}


