/*
C speedups. Thank you very much to:
https://github.com/billywhizz/ws-uv
*/

#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <string.h>

static char encoding_table[] = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
  'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
  'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
  'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3',
  '4', '5', '6', '7', '8', '9', '+', '/'
};

static int mod_table[] = {0, 2, 1};

inline const unsigned int rol(
  const unsigned int value,
  const unsigned int steps
) {
  return ((value << steps) | (value >> (32 - steps)));
}

inline void clearbuffer(unsigned int* buffer) {
  int pos = 16;
  for(; --pos >= 0;) {
    buffer[pos] = 0;
  }
}

void innerhash(unsigned int* result, unsigned int* w) {
  unsigned int
    a = result[0], b = result[1], c = result[2],
    d = result[3], e = result[4];
  int round = 0;
#define sha1macro(func, val) { \
  const unsigned int t = rol(a, 5) + (func) + e + val + w[round]; \
  e = d; \
  d = c; \
  c = rol(b, 30); \
  b = a; \
  a = t; \
}
  while(round < 16) {
    sha1macro((b & c) | (~b & d), 0x5a827999)
    ++round;
  } while(round < 20) {
    w[round] = rol(
      (w[round - 3] ^ w[round - 8] ^ w[round - 14] ^ w[round - 16]), 1);
    sha1macro((b & c) | (~b & d), 0x5a827999)
    ++round;
  } while(round < 40) {
    w[round] = rol(
      (w[round - 3] ^ w[round - 8] ^ w[round - 14] ^ w[round - 16]), 1);
    sha1macro(b ^ c ^ d, 0x6ed9eba1)
    ++round;
  } while(round < 60) {
    w[round] = rol(
      (w[round - 3] ^ w[round - 8] ^ w[round - 14] ^ w[round - 16]), 1);
    sha1macro((b & c) | (b & d) | (c & d), 0x8f1bbcdc)
    ++round;
  } while(round < 80) {
    w[round] = rol(
      (w[round - 3] ^ w[round - 8] ^ w[round - 14] ^ w[round - 16]), 1);
    sha1macro(b ^ c ^ d, 0xca62c1d6)
    ++round;
  }
#undef sha1macro
  result[0] += a;
  result[1] += b;
  result[2] += c;
  result[3] += d;
  result[4] += e;
}

void sha1b64(const char* src, char* dest) {
  // sha1 hash
  int bytelength = strlen(src);
  unsigned int result[5] = {
    0x67452301, 0xefcdab89, 0x98badcfe,
    0x10325476, 0xc3d2e1f0 };
  const unsigned char* sarray = (const unsigned char*) src;
  unsigned int w[80];

  const int end_full_blocks = bytelength - 64;
  int curblock = 0, end_cur_block;  

  while(curblock <= end_full_blocks) {
    end_cur_block = curblock + 64;
    int roundpos = 0;
    for(; curblock < end_cur_block; curblock += 4) {
      w[roundpos++] = (unsigned int) sarray[curblock + 3]
        | (((unsigned int) sarray[curblock + 2]) << 8)
        | (((unsigned int) sarray[curblock + 1]) << 16)
        | (((unsigned int) sarray[curblock])     << 24);
    }
    innerhash(result, w);
  }

  end_cur_block = bytelength - curblock;
  clearbuffer(w);
  int lastbytes = 0;
  for(; lastbytes < end_cur_block; ++lastbytes) {
    w[lastbytes >> 2] |= (unsigned int)
      sarray[lastbytes + curblock] << ((3 - (lastbytes & 3)) << 3);
  }
  w[lastbytes >> 2] |= 0x80 << ((3 - (lastbytes & 3)) << 3);
  
  if (end_cur_block >= 56) {
    innerhash(result, w);
    clearbuffer(w);
  }

  w[15] = bytelength << 3;
  innerhash(result, w);

  unsigned char hash[20];
  int hashbyte = 20;
  for(; --hashbyte >= 0;) {
    hash[hashbyte] = (
      result[hashbyte >> 2] >> (((3 - hashbyte) & 0x3) << 3)
    ) & 0xff;
  }

  // Base64 encode
  int i = 0;
  int j = 0;
  while(i < 20) {
    uint32_t octet_a = i < 20 ? hash[i++] : 0;
    uint32_t octet_b = i < 20 ? hash[i++] : 0;
    uint32_t octet_c = i < 20 ? hash[i++] : 0;
    uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;
    dest[j++] = encoding_table[(triple >> 3 * 6) & 0x3F];
    dest[j++] = encoding_table[(triple >> 2 * 6) & 0x3F];
    dest[j++] = encoding_table[(triple >> 1 * 6) & 0x3F];
    dest[j++] = encoding_table[(triple >> 0 * 6) & 0x3F];
  }
  for(i = 0; i < mod_table[20 % 3]; ++i) {
    dest[28 - 1 - i] = '=';
  }
}