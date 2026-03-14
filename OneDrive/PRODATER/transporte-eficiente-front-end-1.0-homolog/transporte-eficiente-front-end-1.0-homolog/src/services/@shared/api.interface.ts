/* eslint-disable @typescript-eslint/no-explicit-any */
import { patch } from '@/services/@shared/methods/patch'
import { del } from './methods/del'
import { get } from './methods/get'
import { post } from './methods/post'
import { put } from './methods/put'
import type { Axios } from 'axios'

export interface IApiMethods {
  login: (data: any, params?: string) => Promise<any>
  create: (data: any, params?: string) => Promise<any>
  deleteOne: (id: string) => Promise<any>
  getList: (params?: string) => Promise<any>
  getOne: (id: string, params?: string) => Promise<any>
  patch: (data: any, id: string) => Promise<any>
  update: (data: Partial<any>, id: string) => Promise<any>
}

export type PatchResponse<T = any> = {
  data?: T
  error?: string
}

const apiMethods = (fetchInstance: Axios, path: string): IApiMethods => ({
  login: async (data: any, params?: string): Promise<any> => {
    return await post(fetchInstance, path + `${params ?? ''}`, data)
  },
  create: async (data: any, params?: string): Promise<any> => {
    return await post(fetchInstance, path + `${params ?? ''}`, data)
  },
  deleteOne: async (id: string) => {
    return await del(fetchInstance, `${path}/${id}`)
  },
  getList: async (params?: string): Promise<any> => {
    if (params) {
      return await get(fetchInstance, `${path}${params}`)
    } else {
      return await get(fetchInstance, path)
    }
  },
  getOne: async (id: string, params?: string): Promise<any> => {
    if (params) {
      return await get(fetchInstance, `${path}/${id}${params}`)
    } else {
      return await get(fetchInstance, `${path}/${id}`)
    }
  },
  patch: async (data: Partial<any>, id: string) => {
    return await patch(fetchInstance, `${path}/${id}`, data)
  },
  update: async (data: Partial<any>, id: string) => {
    return await put(fetchInstance, `${path}/${id}`, data)
  },
})

export { apiMethods }
