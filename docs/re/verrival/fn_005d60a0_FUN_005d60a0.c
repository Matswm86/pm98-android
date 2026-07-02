// FUN_005d60a0  entry=005d60a0  size=386 bytes

undefined4 __thiscall FUN_005d60a0(int *param_1,ushort param_2)

{
  int iVar1;
  char cVar2;
  int iVar3;
  int iVar4;
  byte bVar5;
  uint uVar6;
  undefined1 uVar7;
  char *pcVar8;
  int *piVar9;
  
  uVar7 = 0;
  if ((*param_1 == 0) && (cVar2 = FUN_005cb2b0(), cVar2 == '\0')) {
    iVar3 = 0;
  }
  else {
    iVar3 = 1;
  }
  if ((char)iVar3 != '\0') {
    iVar1 = param_1[7];
    piVar9 = (int *)*param_1;
    pcVar8 = (char *)((int)piVar9 + (iVar1 + 1) * 2);
    iVar3 = param_1[6] * iVar1;
    iVar4 = (int)(iVar3 + (iVar3 >> 0x1f & 3U)) >> 2;
    uVar6 = (param_1[6] + -4) * iVar1 - 4;
    uVar6 = ((int)uVar6 < 0) - 1 & uVar6;
    iVar3 = -1 - iVar1;
    do {
      while (*pcVar8 != '\0') {
        bVar5 = (byte)(uVar6 >> 8);
        cVar2 = *(char *)((int)&DAT_006b5890 +
                         (((((((((((((uint)(bVar5 < (byte)pcVar8[iVar1 * 2]) << 1 |
                                    (uint)(bVar5 < (byte)pcVar8[iVar1])) << 1 |
                                   (uint)(bVar5 < (byte)pcVar8[iVar1 + 1])) << 1 |
                                  (uint)(bVar5 < (byte)pcVar8[2])) << 1 |
                                 (uint)(bVar5 < (byte)pcVar8[1])) << 1 |
                                (uint)(bVar5 < (byte)pcVar8[1 - iVar1])) << 1 |
                               (uint)(bVar5 < (byte)pcVar8[iVar1 * -2])) << 1 |
                              (uint)(bVar5 < (byte)pcVar8[-iVar1])) << 1 |
                             (uint)(bVar5 < (byte)pcVar8[-1 - iVar1])) << 1 |
                            (uint)(bVar5 < (byte)pcVar8[-2])) << 1 |
                           (uint)(bVar5 < (byte)pcVar8[-1])) << 1 |
                          (uint)(bVar5 < (byte)pcVar8[iVar1 + -1])) << 1 | 1)) * '\x02' + '\x01';
        iVar3 = CONCAT31((int3)((uint)(iVar1 + -1) >> 8),cVar2);
        *pcVar8 = cVar2;
        pcVar8 = pcVar8 + 1;
        uVar6 = uVar6 - 1;
        if (uVar6 == 0) goto LAB_005d61dc;
      }
      pcVar8 = pcVar8 + 1;
      uVar6 = uVar6 - 1;
    } while (uVar6 != 0);
LAB_005d61dc:
    if (param_2 != 0x100) {
      do {
        iVar3 = *piVar9;
        iVar3 = CONCAT31((int3)(CONCAT22((ushort)((ushort)(byte)((uint)iVar3 >> 0x10) *
                                                 (param_2 & 0xff)) >> 8 |
                                         (ushort)(((uint)(byte)((ushort)((ushort)(byte)((uint)iVar3
                                                                                       >> 0x18) *
                                                                        (param_2 & 0xff)) >> 8) <<
                                                  0x18) >> 0x10),
                                         ((ushort)((uint)iVar3 >> 8) & 0xff) * (param_2 & 0xff)) >>
                               8),(char)((ushort)((ushort)((uint)(iVar3 << 0x18) >> 0x18) *
                                                 (param_2 & 0xff)) >> 8));
        iVar4 = iVar4 + -1;
        *piVar9 = iVar3;
        piVar9 = piVar9 + 1;
      } while (iVar4 != 0);
    }
    uVar7 = 1;
  }
  return CONCAT31((int3)((uint)iVar3 >> 8),uVar7);
}


