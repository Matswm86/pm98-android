// FUN_005d6590  entry=005d6590  size=350 bytes

undefined4 __thiscall
FUN_005d6590(int *param_1,int *param_2,undefined1 param_3,byte param_4,ushort param_5)

{
  byte bVar1;
  int iVar2;
  bool bVar3;
  char cVar4;
  byte bVar8;
  int iVar5;
  int iVar6;
  int iVar7;
  undefined1 uVar10;
  byte bVar11;
  int iVar13;
  byte *pbVar14;
  undefined1 *puVar15;
  int *piVar16;
  undefined3 uVar9;
  byte bVar12;
  
  uVar10 = 0;
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
      piVar16 = (int *)*param_1;
      iVar2 = param_1[7];
      puVar15 = (undefined1 *)(iVar2 + 1 + (int)piVar16);
      pbVar14 = (byte *)(param_2[7] + 1 + *param_2);
      iVar5 = iVar2 * param_1[6];
      iVar5 = iVar5 + (iVar5 >> 0x1f & 3U);
      iVar6 = iVar5 >> 2;
      iVar13 = (param_1[6] + -1) * iVar2 + -1;
      iVar7 = (uint)CONCAT21((short)(iVar5 >> 0x12),param_3) << 8;
      do {
        bVar1 = *pbVar14;
        uVar9 = (undefined3)((uint)iVar7 >> 8);
        iVar5 = CONCAT31(uVar9,bVar1);
        pbVar14 = pbVar14 + 1;
        if ((((bVar1 < 0xf0) &&
             (bVar8 = (byte)((uint)iVar7 >> 8),
             bVar12 = (byte)((uint)(byte)puVar15[-iVar2] + (uint)(byte)puVar15[-iVar2 + -1] * 2 +
                             (uint)(byte)puVar15[-1] >> 2), bVar11 = bVar12 - bVar8,
             bVar8 <= bVar12 && bVar11 != 0)) && (bVar1 < bVar11)) &&
           (iVar5 = CONCAT31(uVar9,bVar11), param_4 < bVar11)) {
          iVar5 = CONCAT31(uVar9,param_4);
        }
        *puVar15 = (char)iVar5;
        puVar15 = puVar15 + 1;
        iVar13 = iVar13 + -1;
        iVar7 = iVar5;
      } while (iVar13 != 0);
      if (param_5 != 0x100) {
        do {
          iVar5 = *piVar16;
          iVar5 = CONCAT31((int3)(CONCAT22((ushort)((ushort)(byte)((uint)iVar5 >> 0x10) *
                                                   (param_5 & 0xff)) >> 8 |
                                           (ushort)(((uint)(byte)((ushort)((ushort)(byte)((uint)
                                                  iVar5 >> 0x18) * (param_5 & 0xff)) >> 8) << 0x18)
                                                  >> 0x10),
                                           ((ushort)((uint)iVar5 >> 8) & 0xff) * (param_5 & 0xff))
                                 >> 8),
                           (char)((ushort)((ushort)((uint)(iVar5 << 0x18) >> 0x18) *
                                          (param_5 & 0xff)) >> 8));
          iVar6 = iVar6 + -1;
          *piVar16 = iVar5;
          piVar16 = piVar16 + 1;
        } while (iVar6 != 0);
      }
      uVar10 = 1;
    }
  }
  return CONCAT31((int3)((uint)iVar5 >> 8),uVar10);
}


