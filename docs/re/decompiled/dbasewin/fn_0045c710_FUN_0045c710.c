// FUN_0045c710  entry=0045c710  size=386 bytes

undefined4 __thiscall FUN_0045c710(void *this,ushort param_1)

{
  int iVar1;
  bool bVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  byte bVar6;
  uint uVar7;
  undefined1 uVar8;
  char *pcVar9;
  int *piVar10;
  
  uVar8 = 0;
  if ((*(int *)this != 0) || (bVar2 = FUN_0044e840(this), bVar2)) {
    iVar4 = 1;
  }
  else {
    iVar4 = 0;
  }
  if ((char)iVar4 != '\0') {
    iVar1 = *(int *)((int)this + 0x1c);
    piVar10 = *(int **)this;
    pcVar9 = (char *)((int)piVar10 + (iVar1 + 1) * 2);
    iVar4 = *(int *)((int)this + 0x18) * iVar1;
    iVar5 = (int)(iVar4 + (iVar4 >> 0x1f & 3U)) >> 2;
    uVar7 = (*(int *)((int)this + 0x18) + -4) * iVar1 - 4;
    uVar7 = ((int)uVar7 < 0) - 1 & uVar7;
    iVar4 = -1 - iVar1;
    do {
      while (*pcVar9 != '\0') {
        bVar6 = (byte)(uVar7 >> 8);
        cVar3 = *(char *)((int)&DAT_004f3f80 +
                         (((((((((((((uint)(bVar6 < (byte)pcVar9[iVar1 * 2]) << 1 |
                                    (uint)(bVar6 < (byte)pcVar9[iVar1])) << 1 |
                                   (uint)(bVar6 < (byte)pcVar9[iVar1 + 1])) << 1 |
                                  (uint)(bVar6 < (byte)pcVar9[2])) << 1 |
                                 (uint)(bVar6 < (byte)pcVar9[1])) << 1 |
                                (uint)(bVar6 < (byte)pcVar9[1 - iVar1])) << 1 |
                               (uint)(bVar6 < (byte)pcVar9[iVar1 * -2])) << 1 |
                              (uint)(bVar6 < (byte)pcVar9[-iVar1])) << 1 |
                             (uint)(bVar6 < (byte)pcVar9[-1 - iVar1])) << 1 |
                            (uint)(bVar6 < (byte)pcVar9[-2])) << 1 |
                           (uint)(bVar6 < (byte)pcVar9[-1])) << 1 |
                          (uint)(bVar6 < (byte)pcVar9[iVar1 + -1])) << 1 | 1)) * '\x02' + '\x01';
        iVar4 = CONCAT31((int3)((uint)(iVar1 + -1) >> 8),cVar3);
        *pcVar9 = cVar3;
        pcVar9 = pcVar9 + 1;
        uVar7 = uVar7 - 1;
        if (uVar7 == 0) goto LAB_0045c84c;
      }
      pcVar9 = pcVar9 + 1;
      uVar7 = uVar7 - 1;
    } while (uVar7 != 0);
LAB_0045c84c:
    if (param_1 != 0x100) {
      do {
        iVar4 = *piVar10;
        iVar4 = CONCAT31((int3)(CONCAT22((ushort)((ushort)(byte)((uint)iVar4 >> 0x10) *
                                                 (param_1 & 0xff)) >> 8 |
                                         (ushort)(((uint)(byte)((ushort)((ushort)(byte)((uint)iVar4
                                                                                       >> 0x18) *
                                                                        (param_1 & 0xff)) >> 8) <<
                                                  0x18) >> 0x10),
                                         ((ushort)((uint)iVar4 >> 8) & 0xff) * (param_1 & 0xff)) >>
                               8),(char)((ushort)((ushort)((uint)(iVar4 << 0x18) >> 0x18) *
                                                 (param_1 & 0xff)) >> 8));
        iVar5 = iVar5 + -1;
        *piVar10 = iVar4;
        piVar10 = piVar10 + 1;
      } while (iVar5 != 0);
    }
    uVar8 = 1;
  }
  return CONCAT31((int3)((uint)iVar4 >> 8),uVar8);
}


