# Endpoints del Backend - Parchando App

## Base URL
```
http://localhost:8080
```

## Header Común
Todos los endpoints requieren el header `X-Test-User-Id` para identificar al usuario:
```
X-Test-User-Id: {userId}
```

---

## 1. ENDPOINTS DE AMIGOS (Friends)

### 1.1 GET /friends
Obtiene la lista de amigos del usuario.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200 OK):**
```json
[
  {
    "id": "friend_1",
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "color": -16776961,
    "phone": null,
    "isCurrentUser": false
  },
  {
    "id": "friend_2",
    "name": "María García",
    "email": "maria@example.com",
    "color": -65536,
    "phone": null,
    "isCurrentUser": false
  }
]
```

---

### 1.2 POST /friends
Crea un nuevo amigo para el usuario.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "color": -16776961
}
```

**Response (200/201 OK):**
```json
{
  "id": "friend_1",
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "color": -16776961,
  "phone": null,
  "isCurrentUser": false
}
```

---

### 1.3 DELETE /friends/{friendId}
Elimina un amigo de la lista del usuario.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200/204 OK):**
- Sin body

**Validaciones:**
- Verificar que el amigo pertenezca al usuario

---

## 2. ENDPOINTS DE BILLS (Facturas)

### 2.1 GET /bills
Obtiene todas las facturas del usuario.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200 OK):**
```json
[
  {
    "id": "bill_1",
    "patchId": "patch_1",
    "name": "Dinner Date",
    "date": "2024-09-02T20:00:00.000Z",
    "total": 180.00,
    "items": [
      {
        "id": "item_1",
        "name": "Pizza Margherita",
        "price": 45.00,
        "quantity": 1,
        "participants": [
          {
            "userId": "friend_1",
            "share": 15.00,
            "shareType": "equal",
            "paid": false,
            "paidAmount": 0.00
          },
          {
            "userId": "friend_2",
            "share": 15.00,
            "shareType": "equal",
            "paid": false,
            "paidAmount": 0.00
          }
        ]
      }
    ],
    "taxes": [
      {
        "name": "IVA",
        "amount": 28.80
      }
    ]
  }
]
```

---

### 2.2 GET /bills/{billId}
Obtiene una factura específica por ID.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200 OK):**
```json
{
  "id": "bill_1",
  "patchId": "patch_1",
  "name": "Dinner Date",
  "date": "2024-09-02T20:00:00.000Z",
  "total": 180.00,
  "items": [
    {
      "id": "item_1",
      "name": "Pizza Margherita",
      "price": 45.00,
      "quantity": 1,
      "participants": [
        {
          "userId": "friend_1",
          "share": 15.00,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        }
      ]
    }
  ],
  "taxes": [
    {
      "name": "IVA",
      "amount": 28.80
    }
  ]
}
```

---

### 2.3 POST /bills
Crea una nueva factura.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "id": "bill_1",
  "patchId": "patch_1",
  "name": "Dinner Date",
  "date": "2024-09-02T20:00:00.000Z",
  "total": 180.00,
  "items": [
    {
      "id": "item_1",
      "name": "Pizza Margherita",
      "price": 45.00,
      "quantity": 1,
      "participants": [
        {
          "userId": "friend_1",
          "share": 15.00,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        },
        {
          "userId": "friend_2",
          "share": 15.00,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        },
        {
          "userId": "friend_3",
          "share": 15.00,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        }
      ]
    },
    {
      "id": "item_2",
      "name": "Pasta Carbonara",
      "price": 55.00,
      "quantity": 1,
      "participants": [
        {
          "userId": "friend_4",
          "share": 27.50,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        },
        {
          "userId": "friend_5",
          "share": 27.50,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        }
      ]
    }
  ],
  "taxes": [
    {
      "name": "IVA",
      "amount": 28.80
    }
  ]
}
```

**Response (200/201 OK):**
```json
{
  "id": "bill_1",
  "patchId": "patch_1",
  "name": "Dinner Date",
  "date": "2024-09-02T20:00:00.000Z",
  "total": 180.00,
  "items": [...],
  "taxes": [...]
}
```

**Notas:**
- El `id` puede venir en el request o ser generado por el backend
- Si `patchId` está presente, validar que el usuario sea miembro del patch
- Los `participants` están anidados dentro de cada `item`

---

### 2.4 PUT /bills/{billId}
Actualiza una factura completa.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "id": "bill_1",
  "patchId": "patch_1",
  "name": "Dinner Date Updated",
  "date": "2024-09-02T20:00:00.000Z",
  "total": 200.00,
  "items": [
    {
      "id": "item_1",
      "name": "Pizza Margherita",
      "price": 50.00,
      "quantity": 1,
      "participants": [
        {
          "userId": "friend_1",
          "share": 16.67,
          "shareType": "equal",
          "paid": false,
          "paidAmount": 0.00
        }
      ]
    }
  ],
  "taxes": [
    {
      "name": "IVA",
      "amount": 32.00
    }
  ]
}
```

**Response (200/204 OK):**
- 200 con el bill actualizado, o 204 sin body

**Validaciones:**
- Verificar que el usuario sea miembro del `patchId` asociado (si existe)
- Si el bill no tiene `patchId`, solo el creador puede editarlo

---

### 2.5 PUT /bills/{billId}/items/{itemId}
Actualiza un item específico dentro de una factura.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "id": "item_1",
  "name": "Pizza Margherita",
  "price": 50.00,
  "quantity": 1,
  "participants": [
    {
      "userId": "friend_1",
      "share": 16.67,
      "shareType": "equal",
      "paid": false,
      "paidAmount": 0.00
    },
    {
      "userId": "friend_2",
      "share": 16.67,
      "shareType": "equal",
      "paid": false,
      "paidAmount": 0.00
    },
    {
      "userId": "friend_3",
      "share": 16.67,
      "shareType": "equal",
      "paid": false,
      "paidAmount": 0.00
    }
  ]
}
```

**Response (200/204 OK):**
- 200 con el item actualizado, o 204 sin body

**Validaciones:**
- Verificar que el usuario sea miembro del `patchId` del bill (si existe)

---

### 2.6 DELETE /bills/{billId}
Elimina una factura.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200/204 OK):**
- Sin body

**Validaciones:**
- Verificar que el usuario sea el creador o miembro del patch asociado

---

## 3. ENDPOINTS DE PARCHES (Grupos)

### 3.1 GET /parches
Obtiene todos los parches (grupos) del usuario.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200 OK):**
```json
[
  {
    "id": "patch_1",
    "name": "Viaje a la Costa",
    "icon": "🏖️",
    "memberIds": ["user_1", "user_2", "user_3"],
    "createdAt": "2024-08-01T10:00:00.000Z"
  },
  {
    "id": "patch_2",
    "name": "Apartamento",
    "icon": "🏠",
    "memberIds": ["user_1", "user_4"],
    "createdAt": "2024-07-15T14:30:00.000Z"
  }
]
```

---

### 3.2 POST /parches
Crea un nuevo parche (grupo).

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "id": "patch_1",
  "name": "Viaje a la Costa",
  "icon": "🏖️",
  "memberIds": ["user_1", "user_2", "user_3"],
  "createdAt": "2024-08-01T10:00:00.000Z"
}
```

**Response (200/201 OK):**
```json
{
  "id": "patch_1",
  "name": "Viaje a la Costa",
  "icon": "🏖️",
  "memberIds": ["user_1", "user_2", "user_3"],
  "createdAt": "2024-08-01T10:00:00.000Z"
}
```

**Notas:**
- El `id` puede venir en el request o ser generado por el backend
- El usuario en `X-Test-User-Id` debe estar incluido en `memberIds`

---

### 3.3 DELETE /parches/{patchId}
Elimina un parche (grupo).

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200/204 OK):**
- Sin body

**Validaciones:**
- Verificar que el usuario sea miembro del parche

---

## 4. ENDPOINTS DE RECIBOS (Receipts)

### 4.1 POST /generate-presigned-url
Genera una URL pre-firmada para subir un archivo a S3.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "filename": "receipt_550e8400-e29b-41d4-a716-446655440000.jpg",
  "content_type": "image/jpeg"
}
```

**Response (200 OK):**
```json
{
  "upload_url": "https://s3.amazonaws.com/bucket/receipt_550e8400-e29b-41d4-a716-446655440000.jpg?X-Amz-Algorithm=...",
  "filename": "receipt_550e8400-e29b-41d4-a716-446655440000.jpg"
}
```

**Notas:**
- La URL pre-firmada debe permitir PUT para subir el archivo
- El `filename` debe ser único y se usará como key en S3

---

### 4.2 POST /process-receipt
Procesa un recibo usando OCR después de haber sido subido a S3.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "filename": "receipt_550e8400-e29b-41d4-a716-446655440000.jpg"
}
```

**Response (200 OK):**
```json
{
  "ocr_contents": {
    "items": [
      {
        "id": "item_1725292800000_0",
        "name": "Pizza Margherita",
        "price": 45.00,
        "quantity": 1
      },
      {
        "id": "item_1725292800000_1",
        "name": "Pasta Carbonara",
        "price": 55.00,
        "quantity": 1
      }
    ],
    "total_order_bill_details": {
      "total_bill": 100.00,
      "taxes": [
        {
          "name": "IVA",
          "amount": 16.00
        }
      ]
    }
  }
}
```

**Notas:**
- El `filename` debe coincidir exactamente con la key del archivo en S3
- El backend debe leer el archivo desde S3 usando el `filename`
- Los items pueden venir con o sin `id` (el frontend genera IDs si no vienen)

---

## ESTRUCTURAS DE DATOS

### User
```typescript
{
  id: string;
  name: string;
  email?: string;
  phone?: string;
  color: number; // Color value (int32)
  isCurrentUser?: boolean;
}
```

### BillItem
```typescript
{
  id: string;
  name: string;
  price: number;
  quantity: number;
  participants: ItemParticipant[];
}
```

### ItemParticipant
```typescript
{
  userId: string;
  share: number;
  shareType: "equal" | "custom" | "percentage";
  paid: boolean;
  paidAmount: number;
}
```

### SavedBill
```typescript
{
  id: string;
  patchId?: string;
  name: string;
  date: string; // ISO 8601
  total: number;
  items: BillItem[];
  taxes: Array<{
    name: string;
    amount: number;
  }>;
}
```

### Patch
```typescript
{
  id: string;
  name: string;
  icon?: string;
  memberIds: string[];
  createdAt: string; // ISO 8601
}
```

---

## CÓDIGOS DE RESPUESTA

- **200 OK**: Operación exitosa
- **201 Created**: Recurso creado exitosamente
- **204 No Content**: Operación exitosa sin contenido de respuesta
- **400 Bad Request**: Request inválido
- **401 Unauthorized**: No autenticado
- **403 Forbidden**: No tiene permisos (ej: no es miembro del patch)
- **404 Not Found**: Recurso no encontrado
- **500 Internal Server Error**: Error del servidor

---

## VALIDACIONES IMPORTANTES

1. **X-Test-User-Id**: Todos los endpoints deben validar este header
2. **Permisos de Patch**: Si un bill tiene `patchId`, solo los miembros del patch pueden editarlo
3. **Propiedad de Bill**: Si un bill no tiene `patchId`, solo el creador puede editarlo
4. **Participantes**: Los `participants` están anidados dentro de cada `item`, no en el nivel del bill
5. **Shares**: Los `share` deben calcularse correctamente (normalmente `item.price / participants.length` para `shareType: "equal"`)

---

## NOTAS ADICIONALES

- El frontend usa guardado automático, por lo que los endpoints de actualización (`PUT`) se llaman frecuentemente
- Se recomienda implementar debounce en el backend para evitar actualizaciones excesivas
- Los bills se guardan inmediatamente después de procesar la foto, incluso sin participantes
- El frontend recalcula automáticamente los `share` cuando cambian los precios de los items

---

## ENDPOINTS OPCIONALES (No implementados en frontend actualmente)

Estos endpoints **NO son estrictamente necesarios** para el funcionamiento actual, pero podrían ser útiles para funcionalidades futuras:

### 1. GET /parches/{patchId}
Obtiene un parche específico por ID.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200 OK):**
```json
{
  "id": "patch_1",
  "name": "Viaje a la Costa",
  "icon": "🏖️",
  "memberIds": ["user_1", "user_2", "user_3"],
  "createdAt": "2024-08-01T10:00:00.000Z"
}
```

**Nota:** Útil si se necesita cargar detalles de un parche específico.

---

### 3. PUT /parches/{patchId}
Actualiza un parche (nombre, icono, miembros).

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "name": "Viaje a la Costa Actualizado",
  "icon": "🌴",
  "memberIds": ["user_1", "user_2", "user_3", "user_4"]
}
```

**Response (200/204 OK):**
- 200 con el parche actualizado, o 204 sin body

**Validaciones:**
- Verificar que el usuario sea miembro del parche

**Nota:** Útil para editar parches (actualmente no hay UI para esto).

---

### 4. GET /parches/{patchId}/bills
Obtiene todos los bills asociados a un parche específico.

**Headers:**
```
X-Test-User-Id: {userId}
```

**Response (200 OK):**
```json
[
  {
    "id": "bill_1",
    "patchId": "patch_1",
    "name": "Dinner Date",
    ...
  }
]
```

**Validaciones:**
- Verificar que el usuario sea miembro del parche

**Nota:** Útil para filtrar bills por parche en la UI.

---

### 5. PUT /bills/{billId}/items/{itemId}/participants/{userId}/paid
Marca un participante como pagado en un item específico.

**Headers:**
```
Content-Type: application/json
X-Test-User-Id: {userId}
```

**Request Body:**
```json
{
  "paid": true,
  "paidAmount": 15.00
}
```

**Response (200/204 OK):**
- 200 con el participante actualizado, o 204 sin body

**Alternativa:** Esta funcionalidad puede manejarse con `PUT /bills/{billId}` actualizando el bill completo.

**Nota:** Útil para marcar pagos sin actualizar todo el bill (actualmente no hay UI para esto).

---

## RESUMEN DE ENDPOINTS

### ✅ Endpoints REQUERIDOS (14 endpoints)
1. GET /friends
2. POST /friends
3. DELETE /friends/{friendId}
4. GET /bills
5. GET /bills/{billId}
6. POST /bills
7. PUT /bills/{billId}
8. PUT /bills/{billId}/items/{itemId}
9. DELETE /bills/{billId}
10. GET /parches
11. POST /parches
12. DELETE /parches/{patchId}
13. POST /generate-presigned-url
14. POST /process-receipt

### ⚠️ Endpoints OPCIONALES (4 endpoints)
1. GET /parches/{patchId}
2. PUT /parches/{patchId}
3. GET /parches/{patchId}/bills
4. PUT /bills/{billId}/items/{itemId}/participants/{userId}/paid

**Conclusión:** Los 14 endpoints requeridos son suficientes para el funcionamiento actual de la aplicación. Los 4 opcionales pueden implementarse cuando se necesiten las funcionalidades correspondientes en el frontend.

