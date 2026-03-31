import axios from 'axios';

const apiService = {
    async request({ url, method = 'GET', params = {}, data = {}, headers = {} }) {
        const token = localStorage.getItem('auth_token');
        const combinedHeaders = { ...headers };

        if (token) {
            combinedHeaders['Authorization'] = `Bearer ${token}`;
        }

        if (data && (method === 'POST' || method === 'PUT') && !(data instanceof FormData)) {
            combinedHeaders['Content-Type'] = 'application/json';
        }

        if (method === 'GET' || method === 'DELETE') {
            data = undefined;
        } else {
            params = undefined;
        }

        try {
            const response = await axios({
                url,
                method,
                params,
                data,
                headers: combinedHeaders
            });
            return this.handleResponse(response);
        } catch (error) {
            return this.handleError(error);
        }
    },

    async get(url, params = {}, headers = {}) {
        return this.request({ url, method: 'GET', params, headers });
    },

    async post(url, data = {}, headers = {}) {
        return this.request({ url, method: 'POST', data, headers });
    },

    async put(url, data = {}, headers = {}) {
        return this.request({ url, method: 'PUT', data, headers });
    },

    async delete(url, params = {}, headers = {}) {
        return this.request({ url, method: 'DELETE', params, headers });
    },

    handleResponse(response) {
        return response;
    },

    handleError(error) {
        if (error.response) {
            if (error.response.status === 422) {
                console.error(error.response.data.errors);
            } else if (error.response.status === 401) {
                console.error("401");
            }
        } else if (error.request) {
            console.error(error.request);
        } else {
            console.error(error.message);
        }
        return Promise.reject(error);
    }
};

export default apiService;