// FUN_0045cd60  entry=0045cd60  size=291 bytes

undefined4 __thiscall FUN_0045cd60(void *this,int *param_1,ushort param_2)

{
  undefined4 uVar1;
  byte bVar2;
  bool bVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  undefined1 uVar7;
  undefined4 *puVar8;
  int *piVar9;
  int *piVar10;
  
  uVar7 = 0;
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
      puVar8 = (undefined4 *)*param_1;
      iVar4 = *(int *)((int)this + 0x18) * *(int *)((int)this + 0x1c);
      piVar10 = *(int **)this;
      iVar5 = (int)(iVar4 + (iVar4 >> 0x1f & 3U)) >> 2;
      iVar6 = iVar5;
      piVar9 = piVar10;
      do {
        uVar1 = *puVar8;
        puVar8 = puVar8 + 1;
        bVar2 = -((char)((uint)uVar1 >> 0x10) != '\0');
        iVar4 = CONCAT22((ushort)bVar2 |
                         (ushort)(((uint)CONCAT11(bVar2,-((char)((uint)uVar1 >> 0x18) != '\0')) <<
                                  0x18) >> 0x10),
                         CONCAT11(-((char)((uint)uVar1 >> 8) != '\0'),-((char)uVar1 != '\0')));
        iVar6 = iVar6 + -1;
        *piVar9 = iVar4;
        piVar9 = piVar9 + 1;
      } while (iVar6 != 0);
      if (param_2 != 0x100) {
        do {
          iVar4 = *piVar10;
          iVar4 = CONCAT31((int3)(CONCAT22((ushort)((ushort)(byte)((uint)iVar4 >> 0x10) *
                                                   (param_2 & 0xff)) >> 8 |
                                           (ushort)(((uint)(byte)((ushort)((ushort)(byte)((uint)
                                                  iVar4 >> 0x18) * (param_2 & 0xff)) >> 8) << 0x18)
                                                  >> 0x10),
                                           ((ushort)((uint)iVar4 >> 8) & 0xff) * (param_2 & 0xff))
                                 >> 8),
                           (char)((ushort)((ushort)((uint)(iVar4 << 0x18) >> 0x18) *
                                          (param_2 & 0xff)) >> 8));
          iVar5 = iVar5 + -1;
          *piVar10 = iVar4;
          piVar10 = piVar10 + 1;
        } while (iVar5 != 0);
      }
      uVar7 = 1;
    }
  }
  return CONCAT31((int3)((uint)iVar4 >> 8),uVar7);
}


