// FUN_0045cc00  entry=0045cc00  size=350 bytes

undefined4 __thiscall
FUN_0045cc00(void *this,int *param_1,undefined1 param_2,byte param_3,ushort param_4)

{
  byte bVar1;
  int iVar2;
  bool bVar3;
  byte bVar7;
  int iVar4;
  int iVar5;
  int iVar6;
  undefined1 uVar9;
  byte bVar10;
  int iVar12;
  byte *pbVar13;
  undefined1 *puVar14;
  int *piVar15;
  undefined3 uVar8;
  byte bVar11;
  
  uVar9 = 0;
  if ((*(int *)((int)this + 4) == 0) && (*(int *)this == 0)) {
    bVar3 = false;
  }
  else {
    bVar3 = true;
  }
  if (((!bVar3) || (*(int *)((int)this + 0x14) != param_1[5])) ||
     (*(int *)((int)this + 0x18) != param_1[6])) {
    FUN_0044cfb0(this,param_1[5],param_1[6],8,0,-1);
  }
  if ((*(int *)this != 0) || (bVar3 = FUN_0044e840(this), bVar3)) {
    iVar4 = 1;
  }
  else {
    iVar4 = 0;
  }
  if ((char)iVar4 != '\0') {
    if ((*param_1 != 0) || (bVar3 = FUN_0044e840(param_1), bVar3)) {
      iVar4 = 1;
    }
    else {
      iVar4 = 0;
    }
    if ((char)iVar4 != '\0') {
      piVar15 = *(int **)this;
      iVar2 = *(int *)((int)this + 0x1c);
      puVar14 = (undefined1 *)(iVar2 + 1 + (int)piVar15);
      pbVar13 = (byte *)(param_1[7] + 1 + *param_1);
      iVar4 = iVar2 * *(int *)((int)this + 0x18);
      iVar4 = iVar4 + (iVar4 >> 0x1f & 3U);
      iVar5 = iVar4 >> 2;
      iVar12 = (*(int *)((int)this + 0x18) + -1) * iVar2 + -1;
      iVar6 = (uint)CONCAT21((short)(iVar4 >> 0x12),param_2) << 8;
      do {
        bVar1 = *pbVar13;
        uVar8 = (undefined3)((uint)iVar6 >> 8);
        iVar4 = CONCAT31(uVar8,bVar1);
        pbVar13 = pbVar13 + 1;
        if ((((bVar1 < 0xf0) &&
             (bVar7 = (byte)((uint)iVar6 >> 8),
             bVar11 = (byte)((uint)(byte)puVar14[-iVar2] + (uint)(byte)puVar14[-iVar2 + -1] * 2 +
                             (uint)(byte)puVar14[-1] >> 2), bVar10 = bVar11 - bVar7,
             bVar7 <= bVar11 && bVar10 != 0)) && (bVar1 < bVar10)) &&
           (iVar4 = CONCAT31(uVar8,bVar10), param_3 < bVar10)) {
          iVar4 = CONCAT31(uVar8,param_3);
        }
        *puVar14 = (char)iVar4;
        puVar14 = puVar14 + 1;
        iVar12 = iVar12 + -1;
        iVar6 = iVar4;
      } while (iVar12 != 0);
      if (param_4 != 0x100) {
        do {
          iVar4 = *piVar15;
          iVar4 = CONCAT31((int3)(CONCAT22((ushort)((ushort)(byte)((uint)iVar4 >> 0x10) *
                                                   (param_4 & 0xff)) >> 8 |
                                           (ushort)(((uint)(byte)((ushort)((ushort)(byte)((uint)
                                                  iVar4 >> 0x18) * (param_4 & 0xff)) >> 8) << 0x18)
                                                  >> 0x10),
                                           ((ushort)((uint)iVar4 >> 8) & 0xff) * (param_4 & 0xff))
                                 >> 8),
                           (char)((ushort)((ushort)((uint)(iVar4 << 0x18) >> 0x18) *
                                          (param_4 & 0xff)) >> 8));
          iVar5 = iVar5 + -1;
          *piVar15 = iVar4;
          piVar15 = piVar15 + 1;
        } while (iVar5 != 0);
      }
      uVar9 = 1;
    }
  }
  return CONCAT31((int3)((uint)iVar4 >> 8),uVar9);
}


