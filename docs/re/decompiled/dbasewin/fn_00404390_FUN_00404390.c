// FUN_00404390  entry=00404390  size=183 bytes

void __thiscall FUN_00404390(void *this,uint *param_1,uint param_2)

{
  int iVar1;
  int iVar2;
  
  if (0x80 < (int)param_2) {
    iVar2 = param_2 * -2 + 0x1fe;
    iVar1 = (0x100 - iVar2) * 0xff;
    param_2._0_3_ =
         CONCAT12((char)((uint)*(byte *)((int)this + 2) * iVar2 + iVar1 >> 8),
                  CONCAT11((char)((uint)*(byte *)((int)this + 1) * iVar2 + iVar1 >> 8),
                           (char)(iVar2 * (uint)*(byte *)this + iVar1 >> 8)));
    param_2 = (uint)(uint3)param_2;
    *param_1 = param_2;
    return;
  }
  iVar1 = param_2 * 2;
  param_2._0_3_ =
       CONCAT12((char)((uint)*(byte *)((int)this + 2) * iVar1 >> 8),
                CONCAT11((char)((uint)*(byte *)((int)this + 1) * iVar1 >> 8),
                         (char)(iVar1 * (uint)*(byte *)this >> 8)));
  param_2 = (uint)(uint3)param_2;
  *param_1 = param_2;
  return;
}


