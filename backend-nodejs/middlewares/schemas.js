const { z } = require('zod');

const loginSchema = z.object({
    email: z
        .string({ required_error: 'El correo electrónico es requerido.' })
        .email('El correo electrónico no tiene un formato válido.'),
    password: z
        .string({ required_error: 'La contraseña es requerida.' })
        .min(1, 'La contraseña no puede estar vacía.')
});

const createRoomSchema = z.object({
    roomId: z
        .string({ required_error: 'El ID de sala es requerido.' })
        .min(1, 'El ID de sala no puede estar vacío.'),
    firstName: z
        .string({ required_error: 'El nombre es requerido.' })
        .min(1, 'El nombre no puede estar vacío.'),
    lastName: z.string().optional(),
    email: z
        .string({ required_error: 'El correo electrónico es requerido.' })
        .email('El correo electrónico no tiene un formato válido.'),
    reason: z
        .string({ required_error: 'El motivo de la consulta es requerido.' })
        .min(1, 'El motivo de la consulta no puede estar vacío.'),
    originUrl: z.string().url('La URL de origen no es válida.').optional().or(z.literal(''))
});

const createTicketSchema = z.object({
    roomId: z
        .string({ required_error: 'El ID de sala es requerido.' })
        .min(1, 'El ID de sala no puede estar vacío.'),
    title: z
        .string({ required_error: 'El título es requerido.' })
        .min(1, 'El título no puede estar vacío.')
        .max(255, 'El título no puede superar los 255 caracteres.'),
    description: z.string().optional(),
    status: z.number().int().min(0).max(2).optional(),
    images: z.array(z.string()).optional()
});

const ticketReplySchema = z.object({
    message: z
        .string({ required_error: 'El mensaje de respuesta es requerido.' })
        .min(1, 'El mensaje de respuesta no puede estar vacío.'),
    agentName: z.string().optional(),
    newStatus: z.number().int().min(0).max(2).optional()
});

const updateTicketStatusSchema = z.object({
    status: z
        .number({ required_error: 'El estado es requerido.' })
        .int('El estado debe ser un número entero.')
        .min(0, 'El estado mínimo es 0.')
        .max(2, 'El estado máximo es 2.')
});

const createUserSchema = z.object({
    firstName: z
        .string({ required_error: 'El nombre es requerido.' })
        .min(1, 'El nombre no puede estar vacío.'),
    lastName: z
        .string({ required_error: 'El apellido es requerido.' })
        .min(1, 'El apellido no puede estar vacío.'),
    email: z
        .string({ required_error: 'El correo electrónico es requerido.' })
        .email('El correo electrónico no tiene un formato válido.'),
    password: z
        .string({ required_error: 'La contraseña es requerida.' })
        .min(6, 'La contraseña debe tener al menos 6 caracteres.'),
    roleId: z
        .number({ required_error: 'El rol es requerido.' })
        .int('El rol debe ser un número entero.')
});

const updateUserSchema = z.object({
    firstName: z.string().min(1, 'El nombre no puede estar vacío.').optional(),
    lastName: z.string().min(1, 'El apellido no puede estar vacío.').optional(),
    email: z.string().email('El correo electrónico no tiene un formato válido.').optional(),
    password: z.string().min(6, 'La contraseña debe tener al menos 6 caracteres.').optional().or(z.literal('')),
    roleId: z.number().int().optional()
});

const createProyectoSchema = z.object({
    nombre: z
        .string({ required_error: 'El nombre del proyecto es requerido.' })
        .min(1, 'El nombre del proyecto no puede estar vacío.'),
    descripcion: z.string().optional(),
    estado: z.string().optional(),
    encargadoProyecto: z.number().int().nullish(),
    estimacionInicio: z.string().nullish(),
    estimacionFin: z.string().nullish(),
    assignedBy: z.string().optional()
});

const updateProyectoSchema = createProyectoSchema.partial();

module.exports = {
    loginSchema,
    createRoomSchema,
    createTicketSchema,
    ticketReplySchema,
    updateTicketStatusSchema,
    createUserSchema,
    updateUserSchema,
    createProyectoSchema,
    updateProyectoSchema
};
