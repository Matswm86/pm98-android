// FUN_00458cd0  entry=00458cd0  size=185 bytes

undefined4 __thiscall FUN_00458cd0(void *this,uint param_1,uint param_2,uint param_3,uint param_4)

{
  char cVar1;
  
  cVar1 = FUN_004589b0(this,param_1);
  if (cVar1 != '\0') {
    return *(undefined4 *)
            (*(int *)((int)this + param_1 * 8 + 0x360) + 0x80 + *(int *)((int)this + 0x74) * 0x94);
  }
  cVar1 = FUN_004589b0(this,param_2);
  if (cVar1 != '\0') {
    return *(undefined4 *)
            (*(int *)((int)this + param_2 * 8 + 0x360) + 0x80 + *(int *)((int)this + 0x74) * 0x94);
  }
  cVar1 = FUN_004589b0(this,param_3);
  if (cVar1 != '\0') {
    return *(undefined4 *)
            (*(int *)((int)this + param_3 * 8 + 0x360) + 0x80 + *(int *)((int)this + 0x74) * 0x94);
  }
  cVar1 = FUN_004589b0(this,param_4);
  if (cVar1 != '\0') {
    return *(undefined4 *)
            (*(int *)((int)this + param_4 * 8 + 0x360) + 0x80 + *(int *)((int)this + 0x74) * 0x94);
  }
  return 0;
}


