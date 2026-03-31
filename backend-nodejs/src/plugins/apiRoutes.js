export const apiRoutes = {
    chats: {
        base: () => '/chats',
        getById: (id) => `/chats/${id}`,
        messages: (chatId) => `/chats/${chatId}/messages`
    },
    auth: {
        login: () => '/auth/login',
        register: () => '/auth/register'
    }
};