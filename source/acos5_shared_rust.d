/*
 * acos5_shared_rust.d: Program acos5_gui's shared (with Rust driver) file, mostly types
 *
 * Copyright (C) 2019  Carsten Blüggel <bluecars@posteo.eu>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335  USA.
 */

/* Written in the D programming language */

/*
 * There is no topical reason why things are here other than this one:
 * Code/declarations required by both acos5 driver and tool acos5_gui
 */

module acos5_shared_rust;

import core.stdc.config : c_ulong;
/+
	/* ACOS5 driver */
	SC_CARD_TYPE_ACOS5_BASE = 16000,
	SC_CARD_TYPE_ACOS5_GENERIC,
	SC_CARD_TYPE_ACOS5_32, /* implemented in card-acos5.c (adaption required to be NOT responsible for ATR:
														 3B:BE:96:00:00:41:05:20:00:00:00:00:00:00:00:00:00:90:00 any more, but SC_CARD_TYPE_ACOS5_64_V2 is ! ) */
+/
enum int SC_CARD_TYPE_ACOS5_64_V2  = 16_003; /* driver acos5 implemented as external module: https://github.com/carblue/acos5  */
enum int SC_CARD_TYPE_ACOS5_64_V3  = 16_004; /* driver acos5 */
enum int SC_CARD_TYPE_ACOS5_EVO_V4 = 16_005;

/+
version(Have_acos5_64) {
	enum ISO7816_RFU_TAG_FCP_ : ubyte {
		ISO7816_RFU_TAG_FCP_SFI  = 0x88,  /* L:1,    V: Short File Identifier (SFI). 5 LSbs of File ID if unspecified. Applies to: Any file */
		ISO7816_RFU_TAG_FCP_SAC  = 0x8C,  /* L:0-8,  V: Security Attribute Compact (SAC). Applies to: Any file */
		ISO7816_RFU_TAG_FCP_SEID = 0x8D,  /* L:2,    V: Security Environment File identifier (SE File associated with this DF). Applies to: DFs */
		ISO7816_RFU_TAG_FCP_SAE  = 0xAB,  /* L:0-32, V: Security Attribute Extended (SAE). Applies to: DFs */
	}
	mixin FreeEnumMembers!ISO7816_RFU_TAG_FCP_;
}
+/
//version(OPENSC_VERSION_LATEST)
enum /*ISO7816_RFU_TAG_FCP_ */ : ubyte
{
	ISO7816_RFU_TAG_FCP_SFI  = 0x88,  /* L:1,    V: Short File Identifier (SFI). 5 LSbs of File ID if unspecified. Applies to: Any file */
	ISO7816_RFU_TAG_FCP_SAC  = 0x8C,  /* L:0-8,  V: Security Attribute Compact (SAC). Applies to: Any file */
	ISO7816_RFU_TAG_FCP_SEID = 0x8D,  /* L:2,    V: Security Environment File identifier (SE File associated with this DF). Applies to: DFs */
	ISO7816_RFU_TAG_FCP_SAE  = 0xAB,  /* L:0-32, V: Security Attribute Extended (SAE). Applies to: DFs */
}

//SC_SEC_OPERATION numbering will change (with OpenSC v0.20.0 released?) see constants_types.rs

enum ubyte BLOCKCIPHER_PAD_TYPE_ZEROES              =  0; // as for  CKM_AES_CBC: adds max block size minus one null bytes (0 ≤ N < B Blocksize)
enum ubyte BLOCKCIPHER_PAD_TYPE_ONEANDZEROES        =  1; // Unconditionally add a byte of value 0x80 followed by as many zero bytes as is necessary to fill the input to the next exact multiple of B
// be careful with BLOCKCIPHER_PAD_TYPE_ONEANDZEROES_ACOS5: It can't unambiguously be detected, what is padding, what is payload
enum ubyte BLOCKCIPHER_PAD_TYPE_ONEANDZEROES_ACOS5  =  2; // Used in ACOS5 SM: Only if in_len isn't a multiple of blocksize, then add a byte of value 0x80 followed by as many zero bytes as is necessary to fill the input to the next exact multiple of B
// BLOCKCIPHER_PAD_TYPE_PKCS5 is the recommended one, otherwise BLOCKCIPHER_PAD_TYPE_ONEANDZEROES and BLOCKCIPHER_PAD_TYPE_ANSIX9_23 (BLOCKCIPHER_PAD_TYPE_W3C) also exhibit unambiguity
enum ubyte BLOCKCIPHER_PAD_TYPE_PKCS5               =  3; // as for CKM_AES_CBC_PAD: If the block length is B then add N padding bytes (1 < N ≤ B Blocksize) of value N to make the input length up to the next exact multiple of B. If the input length is already an exact multiple of B then add B bytes of value B
enum ubyte BLOCKCIPHER_PAD_TYPE_ANSIX9_23           =  4; // If N padding bytes are required (1 < N ≤ B Blocksize) set the last byte as N and all the preceding N-1 padding bytes as zero.
// BLOCKCIPHER_PAD_TYPE_W3C is not recommended
//um ubyte BLOCKCIPHER_PAD_TYPE_W3C                 =  5; // If N padding bytes are required (1 < N ≤ B Blocksize) set the last byte as N and all the preceding N-1 padding bytes as arbitrary byte values.

//enum uint SC_SEC_ENV_PARAM_DES_ECB                  = 3;
//enum uint SC_SEC_ENV_PARAM_DES_CBC                  = 4;

/*
 * Proprietary card_ctl calls
 */
//alias card_ctl_tf = int function(sc_card* card, c_ulong request, void* data);

enum c_ulong SC_CARDCTL_ACOS5_GET_COUNT_FILES_CURR_DF   =  0x0000_0011; // data: ushort* (*mut u16)
enum c_ulong SC_CARDCTL_ACOS5_GET_FILE_INFO             =  0x0000_0012; // data: CardCtlArray8*
enum c_ulong SC_CARDCTL_ACOS5_GET_FREE_SPACE            =  0x0000_0014; // data: uint* (*mut u32)
enum c_ulong SC_CARDCTL_ACOS5_GET_IDENT_SELF            =  0x0000_0015; // data: bool* (*mut bool)
enum c_ulong SC_CARDCTL_ACOS5_GET_COS_VERSION           =  0x0000_0016; // data: &ubyte[8]
/* available only since ACOS5-64 V3: */
enum c_ulong SC_CARDCTL_ACOS5_GET_ROM_MANUFACTURE_DATE  =  0x0000_0017; // data: uint* (*mut u32)
enum c_ulong SC_CARDCTL_ACOS5_GET_ROM_SHA1              =  0x0000_0018; // data: &ubyte[20]
enum c_ulong SC_CARDCTL_ACOS5_GET_OP_MODE_BYTE          =  0x0000_0019; // data: ubyte* (*mut u8)
enum c_ulong SC_CARDCTL_ACOS5_GET_FIPS_COMPLIANCE       =  0x0000_001A; // data: bool* (*mut bool)
enum c_ulong SC_CARDCTL_ACOS5_GET_PIN_AUTH_STATE        =  0x0000_001B; // data: CardCtlAuthState*
enum c_ulong SC_CARDCTL_ACOS5_GET_KEY_AUTH_STATE        =  0x0000_001C; // data: CardCtlAuthState*

enum c_ulong SC_CARDCTL_ACOS5_HASHMAP_SET_FILE_INFO     =  0x0000_001E; // data: null
enum c_ulong SC_CARDCTL_ACOS5_HASHMAP_GET_FILE_INFO     =  0x0000_001F; // data: *mut CardCtlArray32

enum c_ulong SC_CARDCTL_ACOS5_SDO_CREATE                =  0x0000_0020; // data: *mut sc_file
enum c_ulong SC_CARDCTL_ACOS5_SDO_DELETE                =  0x0000_0021; // data:
enum c_ulong SC_CARDCTL_ACOS5_SDO_STORE                 =  0x0000_0022; // data:

enum c_ulong SC_CARDCTL_ACOS5_SDO_GENERATE_KEY_FILES  =  0x0000_0023; // data: *mut CardCtl_generate_asym;  RSA files exist, sec_env setting excluded
enum c_ulong SC_CARDCTL_ACOS5_SDO_GENERATE_KEY_FILES_INJECT_SET =  0x0000_0024; // data: *mut CardCtl_generate_inject_asym,do_generate_inject
enum c_ulong SC_CARDCTL_ACOS5_SDO_GENERATE_KEY_FILES_INJECT_GET =  0x0000_0025; // data: *mut CardCtl_generate_inject_asym,do_generate_inject

enum c_ulong SC_CARDCTL_ACOS5_ENCRYPT_SYM               =  0x0000_0027; // data: *mut CardCtl_crypt_sym
enum c_ulong SC_CARDCTL_ACOS5_ENCRYPT_ASYM              =  0x0000_0028; // data: *mut CardCtl_crypt_asym; Signature verification with public key

enum c_ulong SC_CARDCTL_ACOS5_DECRYPT_SYM               =  0x0000_0029; // data: *mut CardCtl_crypt_sym
////enum c_ulong SC_CARDCTL_ACOS5_DECRYPT_ASYM          =  0x0000_002A; // data: *mut CardCtl_crypt_asym; is available via decipher

//enum c_ulong SC_CARDCTL_ACOS5_CREATE_MF_FILESYSTEM      =  0x0000_002B; // data: *mut CardCtlArray20,  create_mf_file_system

/* common types and general function(s) */

// struct for SC_CARDCTL_GET_FILE_INFO and SC_CARDCTL_GET_COS_VERSION
struct CardCtlArray8
{
    ubyte      reference;  // IN  indexing begins with 0, used for SC_CARDCTL_GET_FILE_INFO and more
    ubyte[8]   value;      // OUT
}
/*
// struct for SC_CARDCTL_GET_ROM_SHA1
struct CardCtlArray20
{
    ubyte[20]  value;      // OUT
}
*/
// struct for SC_CARDCTL_GET_PIN_AUTH_STATE and SC_CARDCTL_GET_KEY_AUTH_STATE
struct CardCtlAuthState
{
    ubyte      reference;  // IN  pin/key reference, | 0x80 for local
    bool       value;      // OUT  bool	8 bit byte with the values 0 for false and 1 for true
}

// struct for SC_CARDCTL_GET_FILES_HASHMAP_INFO
struct CardCtlArray32
{
    ushort     key;        // IN   file_id
    ubyte[32]  value;      // OUT  in the order as acos5_gui defines // alias  TreeTypeFS = Tree_k_ary!ub32;
}

struct CardCtl_generate_crypt_asym
{
    ubyte[16]  rsa_pub_exponent;       // public exponent
    ubyte[512] data;
    size_t     data_len;
    ushort     file_id_priv;   // IN  if any of file_id_priv/file_id_pub is 0, then file_id selection will depend on profile,
    ushort     file_id_pub;    // IN  if both are !=0, then the given values are preferred
    ubyte      key_len_code;   //
    ubyte      key_priv_type_code; // as required by cos5 Generate RSA Key Pair

    bool       do_generate_rsa_crt;
    bool       do_generate_rsa_add_decrypt_for_sign;
    bool       do_generate_with_standard_rsa_pub_exponent;   // whether the default exponent 0x10001 shall be used and the exponent field disregarded; otherwise all 16 bytes from exponent will be used

    bool       do_create_files = true;
    bool       perform_mse = true;    // IN parameter, whether MSE Manage Security Env. shall be done prior to crypto operation
//    bool       op_success;     // OUT parameter, whether generation succeeded
}

struct CardCtl_generate_inject_asym {
    ubyte[16]  rsa_pub_exponent; // IN public exponent
    ushort     file_id_priv;       // OUT  if any of file_id_priv/file_id_pub is 0, then file_id selection will depend on acos5_external.profile,
    ushort     file_id_pub;       // OUT  if both are !=0, then the given values are preferred
    bool       do_generate_rsa_crt;         // IN whether RSA private key file shall be generated in ChineseRemainderTheorem-style
    bool       do_generate_rsa_add_decrypt_for_sign; // IN whether RSA private key file shall be generated adding decrypt capability iff sign is requested
    bool       do_generate_with_standard_rsa_pub_exponent; // IN whether RSA key pair will contain the "standard" public exponent e=0x010001==65537; otherwise the user supplied 16 byte exponent will be used
    bool       do_create_files = true; // IN if this is set to true, then the files MUST exist and set in file_id_priv and file_id_pub
}

struct CardCtl_crypt_sym
{
    const(char)*  infile; //  path/to/file where the indata may be read from, interpreted as an [c_uchar]; if!= null has preference over indata
    const(ubyte)* inbuf;
    ubyte[528]    indata;
    size_t        indata_len;
    const(char)*  outfile; //  path/to/file where the outdata may be written to, interpreted as an [c_uchar]; if!= null has preference over outdata
    ubyte*        outbuf;
    ubyte[544]    outdata;
    size_t        outdata_len;
    ubyte[16]     iv;
    size_t        iv_len; // 0==unused or equal to block_size, i.e. 16 for AES, else 8

    uint          algorithm; // e.g. SC_ALGORITHM_AES
    uint          algorithm_flags; // e.g. SC_ALGORITHM_AES_CBC_PAD
//  ubyte key_id; // how the key is known by OpenSC in SKDF: id
    ubyte key_ref; // how the key is known by cos5: e.g. internal local key with id 3 has key_ref: 0x83
    ubyte block_size; // 16: AES; 8: 3DES or DES
    ubyte key_len; // in bytes
    ubyte pad_type; // BLOCKCIPHER_PAD_TYPE_*
//  bool  use_sess_key; // if true, the session key will be used and key_ref ignored
    bool  local;   // whether local or global key to use; used to select MF or appDF where the key file resides
    bool  cbc;     // true: CBC Mode, false: ECB
    bool  encrypt; // true: encrypt,  false: decrypt
    bool  perform_mse;    // IN parameter, whether MSE Manage Security Env. shall be done prior to crypto operation
}
