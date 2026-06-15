// FUN_0057fd60  entry=0057fd60  size=50 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

float10 __thiscall FUN_0057fd60(int param_1,int param_2)

{
  float *pfVar1;
  int iVar2;
  float10 fVar3;
  
  fVar3 = (float10)_DAT_00638dd8;
  iVar2 = 4;
  pfVar1 = (float *)(*(int *)(param_1 + 0x1e4) + 0x14 + param_2 * 0x20c);
  do {
    iVar2 = iVar2 + -1;
    fVar3 = fVar3 + (float10)pfVar1[4] + (float10)*pfVar1;
    pfVar1 = pfVar1 + 1;
  } while (iVar2 != 0);
  return fVar3;
}


