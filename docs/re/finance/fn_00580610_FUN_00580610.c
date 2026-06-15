// FUN_00580610  entry=00580610  size=67 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

float10 __thiscall FUN_00580610(int param_1,int param_2)

{
  uint uVar1;
  float10 fVar2;
  
  fVar2 = (float10)_DAT_00638dd8;
  uVar1 = 0;
  do {
    if (((uVar1 != 9) && (uVar1 != 7)) && (uVar1 != 8)) {
      fVar2 = fVar2 + (float10)*(float *)(*(int *)(param_1 + 0x1e4) + 0xfc +
                                         uVar1 * 4 + param_2 * 0x20c);
    }
    uVar1 = uVar1 + 1;
  } while (uVar1 < 0xe);
  return fVar2;
}


