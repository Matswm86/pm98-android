// FUN_0058c810  entry=0058c810  size=80 bytes

int __thiscall FUN_0058c810(int *param_1,uint *param_2)

{
  ushort uVar1;
  uint uVar2;
  uint uVar3;
  uint *puVar4;
  int iVar5;
  uint uVar6;
  
  uVar1 = *(ushort *)*param_1;
  uVar6 = (uint)uVar1;
  puVar4 = (uint *)((ushort *)*param_1 + 1);
  *param_1 = uVar6 + (int)puVar4;
  for (uVar3 = (uint)(uVar1 >> 2); uVar3 != 0; uVar3 = uVar3 - 1) {
    uVar2 = *puVar4;
    puVar4 = puVar4 + 1;
    *param_2 = uVar2 ^ 0x61616161;
    param_2 = param_2 + 1;
  }
  uVar3 = uVar6 & 3;
  if ((uVar1 & 3) != 0) {
    iVar5 = (int)puVar4 - (int)param_2;
    do {
      *(byte *)param_2 = *(byte *)((int)param_2 + iVar5) ^ 0x61;
      param_2 = (uint *)((int)param_2 + 1);
      uVar3 = uVar3 - 1;
    } while (uVar3 != 0);
  }
  *(byte *)param_2 = 0;
  return uVar6 + 1;
}


